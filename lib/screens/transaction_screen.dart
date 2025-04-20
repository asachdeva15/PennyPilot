import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/category_mapping.dart';
import '../services/file_service.dart';
import '../repositories/file_summary_repository.dart';
import '../models/monthly_detailed_summary.dart';

class TransactionScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final String bankName;

  const TransactionScreen({
    Key? key,
    required this.transactions,
    required this.bankName,
  }) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _uncategorizedTransactions = [];
  Map<String, List<Transaction>> _categorizedTransactions = {};
  bool _isLoading = true;
  final FileService _fileService = FileService();
  CategoryList? _categoryList;
  List<CategoryMapping> _categoryMappings = [];
  bool _showCategorized = true; // State to control visibility of categorized transactions
  bool _showUncategorized = true; // State to control visibility of uncategorized transactions
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load categories
      _categoryList = await _fileService.loadCategoryList();
      
      // Ensure "Other" option is available
      if (_categoryList != null && !_categoryList!.categories.contains('Other')) {
        _categoryList!.categories.add('Other');
        _categoryList!.subcategories['Other'] = ['Other'];
        
        // Add "Other" to all category subcategories
        for (final category in _categoryList!.categories) {
          if (category != 'Other' && 
              !_categoryList!.subcategories[category]!.contains('Other')) {
            _categoryList!.subcategories[category]!.add('Other');
          }
        }
        
        // Save updated category list
        await _fileService.saveCategoryList(_categoryList!);
      }
      
      // Load category mappings
      _categoryMappings = await _fileService.loadAllCategoryMappings();
      
      // Copy transactions and set default Unknown category
      _transactions = widget.transactions.map((t) {
        // Set default Unknown category if not already set
        if (t.category == null || t.subcategory == null) {
          t.category = 'unknown';
          t.subcategory = 'uncategorized';
        }
        return t;
      }).toList();
      
      // Apply any existing category mappings to transactions
      _applyCategoryMappings();
      
      // Organize transactions by category status
      _organizeTransactions();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _organizeTransactions() {
    // Reset lists
    _uncategorizedTransactions = [];
    _categorizedTransactions = {};
    
    // Sort transactions into appropriate lists
    for (var transaction in _transactions) {
      if (transaction.category == 'unknown' || transaction.subcategory == 'uncategorized') {
        _uncategorizedTransactions.add(transaction);
      } else {
        // Categorized transactions go into a map by category
        if (!_categorizedTransactions.containsKey(transaction.category)) {
          _categorizedTransactions[transaction.category!] = [];
        }
        _categorizedTransactions[transaction.category!]!.add(transaction);
      }
    }
    
    // Sort uncategorized transactions by date (newest first)
    _uncategorizedTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Sort each category's transactions by date
    _categorizedTransactions.forEach((category, transactions) {
      transactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }
  
  void _applyCategoryMappings() {
    for (var transaction in _transactions) {
      if (transaction.category == 'unknown' || transaction.subcategory == 'uncategorized') {
        // Try to find a matching category mapping
        for (var mapping in _categoryMappings) {
          if (mapping.matchesDescription(transaction.description, otherData: transaction.otherData)) {
            transaction.category = mapping.category;
            transaction.subcategory = mapping.subcategory;
            transaction.matchedKeyword = mapping.keyword;
            break;
          }
        }
      }
    }
  }
  
  Future<void> _saveTransaction(Transaction transaction) async {
    try {
      // Save the transaction
      await _fileService.saveTransaction(transaction);
      
      // Log to help debug
      debugPrint('Transaction saved: ${transaction.id}, category: ${transaction.category}');
      
      // Get the yearlyData from the YearlyDataRepository to trigger updates
      try {
        // Get the year from the transaction
        final year = transaction.date.year;
        final month = transaction.date.month;
        
        // Update summaries
        debugPrint('Triggering summary updates for year $year month $month');
        
        // Force a regeneration of monthly summary to reflect the new categorization
        try {
          // First, load all transactions for this month
          final allTransactions = await _fileService.loadAllTransactions();
          final monthTransactions = allTransactions.where(
            (t) => t.date.year == year && t.date.month == month
          ).toList();
          
          // Create a detailed summary
          final detailedSummary = MonthlyDetailedSummary.fromTransactions(
            allTransactions, year, month
          );
          
          // Save to repository to trigger summary updates
          final summaryRepo = FileSummaryRepository(fileService: _fileService);
          await summaryRepo.saveMonthlyDetailedSummary(detailedSummary);
          
          debugPrint('Monthly and yearly summaries updated for $year-$month');
        } catch (e) {
          debugPrint('Error updating summaries: $e');
        }
      } catch (e) {
        debugPrint('Error updating yearly data: $e');
      }
      
      // Reorganize transactions after saving
      _organizeTransactions();
      setState(() {}); // Refresh UI
    } catch (e) {
      print('Error saving transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }
  
  /// Saves a keyword-to-category mapping and applies it to matching transactions
  /// 
  /// All parameters must be non-null
  Future<void> _saveKeywordMapping(
    String keyword, 
    String category,  // Non-nullable
    String subcategory,  // Non-nullable
    Transaction transaction
  ) async {
    try {
      // Create and save the category mapping
      final mapping = CategoryMapping(
        keyword: keyword,
        category: category,
        subcategory: subcategory,
      );
      
      final success = await _fileService.saveCategoryMapping(mapping);
      
      if (!success) {
        // If save failed, show error and exit
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving keyword mapping')),
        );
        return;
      }
      
      // Add to local list for immediate use
      _categoryMappings.add(mapping);
      
      // Apply to matching transactions and track which ones were changed
      List<Transaction> updatedTransactions = [];
      
      for (var t in _transactions) {
        if (mapping.matchesDescription(t.description, otherData: t.otherData)) {
          t.category = category;
          t.subcategory = subcategory;
          t.matchedKeyword = keyword;
          updatedTransactions.add(t);
          
          // Save the updated transaction
          await _fileService.saveTransaction(t);
        }
      }
      
      // Only reorganize and update UI if we actually updated any transactions
      if (updatedTransactions.isNotEmpty) {
        _organizeTransactions();
        setState(() {});  // Trigger UI rebuild
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keyword mapping saved and applied to ${updatedTransactions.length} transactions')),
      );
    } catch (e) {
      print('Error saving keyword mapping: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving keyword mapping: $e')),
      );
    }
  }
  
  void _showCategoryDialog(Transaction transaction) {
    if (_categoryList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category list not loaded yet')),
      );
      return;
    }
    
    String? selectedCategory = transaction.category;
    String? selectedSubcategory = transaction.subcategory;
    bool isOtherCategory = false;
    bool isOtherSubcategory = false;
    bool createMappingRule = true;
    
    // Controllers for new inputs
    final TextEditingController newCategoryController = TextEditingController();
    final TextEditingController newSubcategoryController = TextEditingController();
    final TextEditingController keywordController = TextEditingController();
    // Initialize keyword with a good guess based on the description
    keywordController.text = _extractKeywordFromDescription(transaction.description);
    
    // Add controller for otherData
    final TextEditingController otherDataController = TextEditingController(
      text: (transaction.otherData != null && transaction.otherData!.isNotEmpty) 
        ? transaction.otherData! 
        : "NONE"
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Generate the list of categories
            final categories = _categoryList!.categories;
            
            // Generate the list of subcategories for the selected category
            List<String> subcategories = [];
            if (selectedCategory != null && _categoryList!.subcategories.containsKey(selectedCategory)) {
              subcategories = _categoryList!.subcategories[selectedCategory]!;
            }
            
            return AlertDialog(
              title: const Text('Categorize Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction details
                    Text('Description: ${transaction.description}'),
                    Text('Amount: ${transaction.amount.toStringAsFixed(2)}'),
                    Text('Date: ${transaction.date.toString().substring(0, 10)}'),
                    
                    const SizedBox(height: 16),
                    
                    // Other data field
                    TextField(
                      controller: otherDataController,
                      decoration: const InputDecoration(
                        labelText: 'Other Information',
                        hintText: 'Additional transaction data',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Make it read-only since it comes from CSV mapping
                      style: TextStyle(
                        fontStyle: transaction.otherData != null && transaction.otherData!.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                        color: transaction.otherData != null && transaction.otherData!.isNotEmpty
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          selectedSubcategory = null; // Reset subcategory on category change
                          
                          isOtherCategory = value == 'Other';
                          isOtherSubcategory = false;
                        });
                      },
                    ),
                    
                    // "Other" category text field
                    if (isOtherCategory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: newCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Category Name',
                          hintText: 'Enter a name for your new category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Subcategory dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedSubcategory,
                      items: subcategories.map((subcategory) {
                        return DropdownMenuItem(
                          value: subcategory,
                          child: Text(subcategory),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubcategory = value;
                          isOtherSubcategory = value == 'Other';
                        });
                      },
                    ),
                    
                    // "Other" subcategory text field
                    if (isOtherSubcategory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: newSubcategoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Subcategory Name',
                          hintText: 'Enter a name for your new subcategory',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Keyword input for mapping
                    TextField(
                      controller: keywordController,
                      decoration: const InputDecoration(
                        labelText: 'Keyword for mapping',
                        hintText: 'Enter a keyword to match similar transactions',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Checkbox to create mapping rule
                    Row(
                      children: [
                        Checkbox(
                          value: createMappingRule,
                          onChanged: (value) {
                            setState(() {
                              createMappingRule = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Create rule for similar transactions',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    
                    if (createMappingRule)
                      const Padding(
                        padding: EdgeInsets.only(left: 32.0),
                        child: Text(
                          'Transactions containing this keyword will be automatically categorized',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _onSaveCategory(
                      context,
                      transaction,
                      selectedCategory,
                      selectedSubcategory,
                      isOtherCategory,
                      isOtherSubcategory,
                      newCategoryController,
                      newSubcategoryController,
                      keywordController,
                      otherDataController,
                      createMappingRule,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onSaveCategory(
    BuildContext context,
    Transaction transaction,
    String? selectedCategory,
    String? selectedSubcategory,
    bool isOtherCategory,
    bool isOtherSubcategory,
    TextEditingController newCategoryController,
    TextEditingController newSubcategoryController,
    TextEditingController keywordController,
    TextEditingController otherDataController,
    bool createMappingRule,
  ) async {
    try {
      // Handle "Other" category input
      if (isOtherCategory && newCategoryController.text.isNotEmpty) {
        selectedCategory = newCategoryController.text;
        
        // Add new category to the list if it doesn't exist
        if (!_categoryList!.categories.contains(selectedCategory)) {
          _categoryList!.categories.add(selectedCategory!);
          _categoryList!.subcategories[selectedCategory!] = ['Other'];
          
          // Save the updated category list
          await _fileService.saveCategoryList(_categoryList!);
        }
      }
      
      // Handle "Other" subcategory input
      if (isOtherSubcategory && newSubcategoryController.text.isNotEmpty && selectedCategory != null) {
        selectedSubcategory = newSubcategoryController.text;
        
        // Add new subcategory to the list
        if (!_categoryList!.subcategories[selectedCategory!]!.contains(selectedSubcategory)) {
          _categoryList!.subcategories[selectedCategory!]!.add(selectedSubcategory!);
          
          // Save the updated category list
          await _fileService.saveCategoryList(_categoryList!);
        }
      }
      
      // Update the transaction
      if (selectedCategory != null && selectedSubcategory != null) {
        transaction.category = selectedCategory;
        transaction.subcategory = selectedSubcategory;
        
        // Set the otherData field
        transaction.otherData = otherDataController.text.trim() != "NONE" ? 
                              otherDataController.text.trim() : 
                              transaction.otherData;
        
        Navigator.of(context).pop();
        
        // Save the transaction with its new category
        await _saveTransaction(transaction);
        
        // Also create a mapping if the checkbox is checked and keyword is provided
        final keyword = keywordController.text.trim();
        if (createMappingRule && keyword.isNotEmpty) {
          await _saveKeywordMapping(
            keyword,
            selectedCategory!,
            selectedSubcategory!,
            transaction
          );
        }
      } else {
        // Show error if category or subcategory is not selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both category and subcategory')),
        );
      }
    } catch (e) {
      print('Error saving transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions - ${widget.bankName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Uncategorized Transactions Header with collapsible functionality
                if (_uncategorizedTransactions.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showUncategorized = !_showUncategorized;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            'Uncategorized Transactions',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_uncategorizedTransactions.length} items',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showUncategorized ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Uncategorized Transactions List (collapsible)
                Expanded(
                  child: ListView.builder(
                    itemCount: (_showUncategorized ? _uncategorizedTransactions.length : 0) + 
                              (_categorizedTransactions.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      // First display all uncategorized transactions if not collapsed
                      if (_showUncategorized && index < _uncategorizedTransactions.length) {
                        return _buildTransactionCard(_uncategorizedTransactions[index]);
                      } 
                      // Then display the categorized section toggle
                      else if (_categorizedTransactions.isNotEmpty) {
                        // Adjust index if uncategorized is collapsed
                        final adjustedIndex = _showUncategorized 
                            ? index - _uncategorizedTransactions.length
                            : index;
                        
                        if (adjustedIndex == 0) {
                          return _buildCategorizedSection();
                        }
                      }
                      
                      return Container(); // Fallback
                    },
                  ),
                ),
              ],
            ),
    );
  }
  
  // Build a transaction card with category status indicator
  Widget _buildTransactionCard(Transaction transaction) {
    // Determine if the transaction is categorized as Unknown
    bool isUnknown = transaction.category == 'unknown' || 
                     transaction.subcategory == 'uncategorized';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(transaction.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date display - using MM/DD/YYYY format to match CSV
                Text(
                  '${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                // Category status
                Text(
                  '#${transaction.category}',
                  style: TextStyle(
                    color: isUnknown ? Colors.red : Colors.amber[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (transaction.subcategory != null && !isUnknown)
              Text(
                transaction.subcategory!,
                style: TextStyle(
                  color: Colors.amber[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Text(
          transaction.amount.toStringAsFixed(2),
          style: TextStyle(
            color: transaction.amount < 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          _showCategoryDialog(transaction);
        },
      ),
    );
  }
  
  // Build the collapsible categorized transactions section
  Widget _buildCategorizedSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () {
              setState(() {
                _showCategorized = !_showCategorized;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Categorized Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showCategorized ? Icons.expand_less : Icons.expand_more,
                    color: Colors.amber[800],
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          if (_showCategorized)
            ...(_categorizedTransactions.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category header
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 12.0, bottom: 4.0),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Transactions in this category
                  ...entry.value.map((transaction) => _buildTransactionCard(transaction))
                ],
              );
            }).toList()),
        ],
      ),
    );
  }

  // Helper method to extract a keyword from a transaction description
  String _extractKeywordFromDescription(String description) {
    // Try to extract a potential keyword from the description
    final words = description.split(' ')
      .where((word) => word.length > 3)
      .toList();
    
    if (words.isNotEmpty) {
      // Default to the longest word as a potential keyword
      words.sort((a, b) => b.length.compareTo(a.length));
      return words.first;
    }
    
    return '';
  }
} 