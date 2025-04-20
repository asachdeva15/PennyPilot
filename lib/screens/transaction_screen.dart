import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category_mapping.dart';
import '../services/file_service.dart';

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
          if (mapping.matchesDescription(transaction.description)) {
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
      await _fileService.saveTransaction(transaction);
      
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
      
      await _fileService.saveCategoryMapping(mapping);
      
      // Add to local list for immediate use
      _categoryMappings.add(mapping);
      
      // Apply to matching transactions and track which ones were changed
      List<Transaction> updatedTransactions = [];
      
      for (var t in _transactions) {
        if (mapping.matchesDescription(t.description)) {
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
    // Initialize with transaction's current values or null
    String? selectedCategory = transaction.category;
    String? selectedSubcategory = transaction.subcategory;
    
    // Controllers for new category/subcategory input
    final newCategoryController = TextEditingController();
    final newSubcategoryController = TextEditingController();
    
    // Suggest a keyword from the description
    final words = transaction.description.split(' ')
      .where((word) => word.length > 3)
      .toList();
    String keywordSuggestion = words.isNotEmpty ? words.first : '';
    
    // Create a controller with the initial value
    final keywordController = TextEditingController(text: keywordSuggestion);
    
    // Ensure we have a valid category list
    if (_categoryList == null) {
      _categoryList = CategoryList.getDefault();
      
      // Add "Other" option
      if (!_categoryList!.categories.contains('Other')) {
        _categoryList!.categories.add('Other');
        _categoryList!.subcategories['Other'] = ['Other'];
        
        // Add "Other" to all category subcategories
        for (final category in _categoryList!.categories) {
          if (category != 'Other' && 
              !_categoryList!.subcategories[category]!.contains('Other')) {
            _categoryList!.subcategories[category]!.add('Other');
          }
        }
      }
    }
    
    // Debug print to help diagnose the issue
    debugPrint('Available categories: ${_categoryList!.categories}');
    debugPrint('Selected category: $selectedCategory');
    
    // Make sure selectedCategory exists in our category list
    if (selectedCategory == null || !_categoryList!.categories.contains(selectedCategory)) {
      selectedCategory = 'unknown'; // Default to 'unknown' if invalid
      debugPrint('Corrected selected category to: $selectedCategory');
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isOtherCategory = selectedCategory == 'Other';
            bool isOtherSubcategory = selectedSubcategory == 'Other';
            
            // Create a local copy of categories for the dropdown
            final categories = List<String>.from(_categoryList!.categories);
            
            // Get subcategories for selected category
            List<String> subcategories = [];
            if (selectedCategory != null) {
              subcategories = List<String>.from(
                _categoryList!.subcategories[selectedCategory] ?? []
              );
              
              // Validate that the subcategory exists in our list
              if (selectedSubcategory != null && !subcategories.contains(selectedSubcategory)) {
                selectedSubcategory = subcategories.isNotEmpty ? subcategories.first : null;
              }
            }
            
            // Ensure dropdown values match available items
            bool categoryExists = categories.contains(selectedCategory);
            bool subcategoryExists = selectedSubcategory != null && subcategories.contains(selectedSubcategory);
            
            if (!categoryExists && categories.isNotEmpty) {
              selectedCategory = categories.first;
              debugPrint('Adjusted selectedCategory to: $selectedCategory');
            }
            
            if (!subcategoryExists && subcategories.isNotEmpty) {
              selectedSubcategory = subcategories.first;
              debugPrint('Adjusted selectedSubcategory to: $selectedSubcategory');
            }
            
            return AlertDialog(
              title: const Text('Categorize Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Amount: ${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: transaction.amount < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Category:'),
                    DropdownButton<String>(
                      value: categoryExists ? selectedCategory : null,
                      isExpanded: true,
                      hint: const Text('Select a category'),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                            isOtherCategory = value == 'Other';
                            selectedSubcategory = null; // Reset subcategory when category changes
                          });
                        }
                      },
                    ),
                    // Show text field for new category if "Other" is selected
                    if (isOtherCategory) ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Enter new category name',
                          border: OutlineInputBorder(),
                        ),
                        controller: newCategoryController,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text('Subcategory:'),
                    if (subcategories.isEmpty)
                      const Text('No subcategories available')
                    else
                      DropdownButton<String>(
                        value: subcategoryExists ? selectedSubcategory : null,
                        isExpanded: true,
                        hint: const Text('Select a subcategory'),
                        items: subcategories.map((subcategory) {
                          return DropdownMenuItem<String>(
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
                    // Show text field for new subcategory if "Other" is selected
                    if (isOtherSubcategory && selectedCategory != null) ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Enter new subcategory name',
                          border: OutlineInputBorder(),
                        ),
                        controller: newSubcategoryController,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Keyword for similar transactions:'),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Enter keyword from description',
                      ),
                      controller: keywordController,
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
                    // Check for required field values
                    if (selectedCategory == null || selectedSubcategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both category and subcategory')),
                      );
                      return;
                    }
                    
                    // Check if keyword is entered
                    if (keywordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a keyword for mapping')),
                      );
                      return;
                    }
                    
                    // Process "Other" selections
                    String finalCategory = selectedCategory!;
                    String finalSubcategory = selectedSubcategory!;
                    
                    // Handle new category if "Other" is selected
                    if (isOtherCategory && newCategoryController.text.isNotEmpty) {
                      finalCategory = newCategoryController.text.trim();
                      
                      // Add to category list if it doesn't exist
                      if (!_categoryList!.categories.contains(finalCategory)) {
                        _categoryList!.categories.add(finalCategory);
                        _categoryList!.subcategories[finalCategory] = ['Other'];
                        await _fileService.saveCategoryList(_categoryList!);
                      }
                    }
                    
                    // Handle new subcategory if "Other" is selected
                    if (isOtherSubcategory && newSubcategoryController.text.isNotEmpty) {
                      finalSubcategory = newSubcategoryController.text.trim();
                      
                      // Add to subcategory list if it doesn't exist
                      if (!_categoryList!.subcategories[finalCategory]!.contains(finalSubcategory)) {
                        _categoryList!.subcategories[finalCategory]!.add(finalSubcategory);
                        await _fileService.saveCategoryList(_categoryList!);
                      }
                    }
                    
                    debugPrint('Saving with category: $finalCategory, subcategory: $finalSubcategory');
                    
                    // Update the transaction
                    transaction.category = finalCategory;
                    transaction.subcategory = finalSubcategory;
                    
                    // Save the transaction to persist changes
                    await _saveTransaction(transaction);
                    
                    // Always save keyword mapping
                    await _saveKeywordMapping(
                      keywordController.text,
                      finalCategory,
                      finalSubcategory,
                      transaction,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
} 