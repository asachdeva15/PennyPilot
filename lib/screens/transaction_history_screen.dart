import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category_mapping.dart';
import '../models/yearly_data.dart';
import '../repositories/yearly_data_repository.dart';
import '../services/file_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final YearlyDataRepository _yearlyRepo = YearlyDataRepository();
  final FileService _fileService = FileService();
  
  bool _isLoading = true;
  List<Transaction> _allTransactions = [];
  Map<String, List<Transaction>> _groupedTransactions = {};
  List<String> _categories = [];
  Map<String, List<String>> _subcategories = {};

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
      await _yearlyRepo.initialize();
      
      // Get the current year's data
      final currentYear = DateTime.now().year;
      final yearlyData = await _yearlyRepo.getYearlyData(currentYear);
      
      if (yearlyData != null) {
        // Extract all transactions from all months
        _allTransactions = _extractAllTransactions(yearlyData);
      }
      
      // Get transactions from previous years if available
      try {
        final lastYear = await _yearlyRepo.getYearlyData(currentYear - 1);
        if (lastYear != null) {
          _allTransactions.addAll(_extractAllTransactions(lastYear));
        }
      } catch (e) {
        print('No data for previous year: $e');
      }
      
      // Sort transactions by date (newest first)
      _allTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Group transactions by bank name
      _groupedTransactions = {};
      for (final transaction in _allTransactions) {
        final bankName = transaction.bankName ?? 'Unknown Bank';
        if (!_groupedTransactions.containsKey(bankName)) {
          _groupedTransactions[bankName] = [];
        }
        _groupedTransactions[bankName]!.add(transaction);
      }
      
      // Load categories and subcategories
      await _loadCategories();
      
    } catch (e) {
      print('Error loading transaction history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Transaction> _extractAllTransactions(YearlyData yearlyData) {
    List<Transaction> transactions = [];
    
    for (final monthEntry in yearlyData.months.entries) {
      final monthData = monthEntry.value;
      transactions.addAll(monthData.transactions);
    }
    
    return transactions;
  }

  Future<void> _loadCategories() async {
    try {
      await _fileService.initializeStorage();
      
      // Get the complete list of categories from CategoryList
      final categoryList = await _fileService.loadCategoryList();
      
      // Start with the full set of categories from CategoryList
      _categories = List<String>.from(categoryList.categories);
      _subcategories = {};
      
      // Initialize subcategories from CategoryList
      for (final category in _categories) {
        if (categoryList.subcategories.containsKey(category)) {
          _subcategories[category] = List<String>.from(categoryList.subcategories[category] ?? []);
        } else {
          _subcategories[category] = [];
        }
      }
      
      // Ensure "Uncategorized" is available if not already in the list
      if (!_categories.contains('Uncategorized')) {
        _categories.add('Uncategorized');
        _subcategories['Uncategorized'] = ['Uncategorized'];
      }
      
      // Also add subcategories from existing transactions (might be custom ones)
      for (final transaction in _allTransactions) {
        if (transaction.category != null && transaction.category!.isNotEmpty) {
          if (!_categories.contains(transaction.category)) {
            _categories.add(transaction.category!);
            _subcategories[transaction.category!] = [];
          }
          
          if (transaction.subcategory != null && transaction.subcategory!.isNotEmpty) {
            if (!_subcategories[transaction.category!]!.contains(transaction.subcategory)) {
              _subcategories[transaction.category!]!.add(transaction.subcategory!);
            }
          }
        }
      }
      
      // Add categories and subcategories from mappings to catch any additional ones
      final categoryMappings = await _fileService.loadAllCategoryMappings();
      for (final mapping in categoryMappings) {
        if (!_categories.contains(mapping.category)) {
          _categories.add(mapping.category);
          _subcategories[mapping.category] = [];
        }
        
        if (mapping.subcategory.isNotEmpty && 
            !_subcategories[mapping.category]!.contains(mapping.subcategory)) {
          _subcategories[mapping.category]!.add(mapping.subcategory);
        }
      }
      
      // Sort categories and subcategories alphabetically
      _categories.sort();
      for (final category in _subcategories.keys) {
        _subcategories[category]!.sort();
      }
      
      print('Loaded categories: $_categories');
      for (final category in _categories) {
        print('Subcategories for $category: ${_subcategories[category]}');
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _updateTransaction(Transaction transaction, {String? category, String? subcategory}) async {
    try {
      // Create updated transaction
      final updatedTransaction = transaction.copyWith(
        category: category ?? transaction.category,
        subcategory: subcategory ?? transaction.subcategory,
      );
      
      // Update in repository
      final success = await _yearlyRepo.updateTransaction(updatedTransaction);
      
      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated successfully')),
          );
        }
        
        // Refresh data
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update transaction')),
          );
        }
      }
    } catch (e) {
      print('Error updating transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  void _showCategorySelectionDialog(Transaction transaction) {
    // Try to guess best category based on description
    String? suggestedCategory = _suggestCategoryForTransaction(transaction);
    
    String? selectedCategory = transaction.category ?? suggestedCategory;
    String? selectedSubcategory = transaction.subcategory;
    
    // For new category/subcategory input
    final TextEditingController newCategoryController = TextEditingController();
    final TextEditingController newSubcategoryController = TextEditingController();
    bool isAddingNewCategory = false;
    bool isAddingNewSubcategory = false;
    
    // Select subcategory for streaming services
    if (selectedCategory == 'Lifestyle' && transaction.description.toLowerCase().contains('netflix')) {
      selectedSubcategory = 'Subscriptions';
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Transaction Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction: ${transaction.description}'),
                    Text('Amount: ${NumberFormat.currency(locale: 'de_DE', symbol: '€').format(transaction.amount)}'),
                    Text('Date: ${DateFormat('yyyy-MM-dd').format(transaction.date)}'),
                    const SizedBox(height: 16),
                    
                    // Category selection or input field
                    if (!isAddingNewCategory) ...[
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              isExpanded: true,
                              value: selectedCategory,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Select Category'),
                                ),
                                ..._categories.map((category) => DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value;
                                  selectedSubcategory = null; // Reset subcategory when category changes
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Add New Category',
                            onPressed: () {
                              setDialogState(() {
                                isAddingNewCategory = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newCategoryController,
                              decoration: const InputDecoration(
                                labelText: 'New Category Name',
                                hintText: 'Enter new category',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: 'Confirm New Category',
                            onPressed: () {
                              final newCategory = newCategoryController.text.trim();
                              if (newCategory.isNotEmpty) {
                                setDialogState(() {
                                  if (!_categories.contains(newCategory)) {
                                    _categories.add(newCategory);
                                    _categories.sort();
                                    _subcategories[newCategory] = [];
                                  }
                                  selectedCategory = newCategory;
                                  isAddingNewCategory = false;
                                  selectedSubcategory = null;
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: 'Cancel',
                            onPressed: () {
                              setDialogState(() {
                                isAddingNewCategory = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Subcategory dropdown or input field (only show if category is selected)
                    if (selectedCategory != null) ...[
                      if (!isAddingNewSubcategory) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Subcategory',
                                ),
                                isExpanded: true,
                                value: selectedSubcategory,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Select Subcategory'),
                                  ),
                                  ...(_subcategories[selectedCategory] ?? []).map((subcategory) => DropdownMenuItem<String>(
                                    value: subcategory,
                                    child: Text(subcategory),
                                  )).toList(),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedSubcategory = value;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Add New Subcategory',
                              onPressed: () {
                                setDialogState(() {
                                  isAddingNewSubcategory = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newSubcategoryController,
                                decoration: const InputDecoration(
                                  labelText: 'New Subcategory Name',
                                  hintText: 'Enter new subcategory',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip: 'Confirm New Subcategory',
                              onPressed: () {
                                final newSubcategory = newSubcategoryController.text.trim();
                                if (newSubcategory.isNotEmpty && selectedCategory != null) {
                                  setDialogState(() {
                                    if (!_subcategories.containsKey(selectedCategory)) {
                                      _subcategories[selectedCategory!] = [];
                                    }
                                    if (!_subcategories[selectedCategory]!.contains(newSubcategory)) {
                                      _subcategories[selectedCategory]!.add(newSubcategory);
                                      _subcategories[selectedCategory]!.sort();
                                    }
                                    selectedSubcategory = newSubcategory;
                                    isAddingNewSubcategory = false;
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              tooltip: 'Cancel',
                              onPressed: () {
                                setDialogState(() {
                                  isAddingNewSubcategory = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmationDialog(transaction);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateTransaction(
                      transaction, 
                      category: selectedCategory,
                      subcategory: selectedSubcategory,
                    );
                  },
                  child: const Text('Update'),
                ),
                if (selectedCategory != null && transaction.description.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAddKeywordMappingDialog(
                        transaction.description,
                        selectedCategory!,
                        selectedSubcategory,
                      );
                    },
                    child: const Text('Update & Create Rule'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to suggest category based on transaction description
  String? _suggestCategoryForTransaction(Transaction transaction) {
    final description = transaction.description.toLowerCase();
    
    // Common streaming services and subscriptions
    if (description.contains('netflix') || 
        description.contains('spotify') || 
        description.contains('disney') ||
        description.contains('hbo') ||
        description.contains('subscription')) {
      return 'Lifestyle';
    }
    
    // Grocery and food
    if (description.contains('rewe') || 
        description.contains('edeka') || 
        description.contains('aldi') ||
        description.contains('lidl') ||
        description.contains('kaufland') ||
        description.contains('grocery') ||
        description.contains('supermarket')) {
      return 'Fundamentals';
    }
    
    // Income
    if (description.contains('salary') || 
        description.contains('gehalt') || 
        description.contains('lohn') ||
        description.contains('income') ||
        description.contains('wages') ||
        transaction.amount > 0) {
      return 'Income';
    }
    
    return null;
  }

  void _showAddKeywordMappingDialog(String description, String category, String? subcategory) {
    String keyword = '';
    
    // Try to extract a potential keyword from the description
    final words = description.split(' ')
      .where((word) => word.length > 3)
      .toList();
    
    if (words.isNotEmpty) {
      // Default to the longest word as a potential keyword
      words.sort((a, b) => b.length.compareTo(a.length));
      keyword = words.first;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Category Mapping Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: $description'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Keyword',
                  hintText: 'Enter keyword to match in descriptions',
                ),
                controller: TextEditingController(text: keyword),
                onChanged: (value) {
                  keyword = value;
                },
              ),
              const SizedBox(height: 8),
              Text('Category: $category'),
              if (subcategory != null)
                Text('Subcategory: $subcategory'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                if (keyword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Keyword cannot be empty')),
                  );
                  return;
                }
                
                try {
                  // Create and save the category mapping
                  final newMapping = CategoryMapping(
                    keyword: keyword,
                    category: category,
                    subcategory: subcategory ?? '',
                  );
                  
                  final success = await _fileService.saveCategoryMapping(newMapping);
                  
                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Rule created for keyword "$keyword"')),
                      );
                    }
                    
                    // Reload data to apply the new rule
                    await _loadData();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create rule')),
                      );
                    }
                  }
                } catch (e) {
                  print('Error creating category mapping: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating rule: $e')),
                    );
                  }
                }
              },
              child: const Text('Create Rule'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to handle transaction deletion
  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      // Delete the transaction using the repo
      final success = await _yearlyRepo.deleteTransaction(transaction);
      
      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
        
        // Refresh data
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete transaction')),
          );
        }
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  // Show confirmation dialog before deletion
  void _showDeleteConfirmationDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this transaction? This cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Description: ${transaction.description}'),
            Text('Amount: ${NumberFormat.currency(locale: 'de_DE', symbol: '€').format(transaction.amount)}'),
            Text('Date: ${DateFormat('yyyy-MM-dd').format(transaction.date)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTransaction(transaction);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFFE68A00),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTransactions.isEmpty
              ? const Center(child: Text('No transactions found'))
              : _buildTransactionList(),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      itemCount: _groupedTransactions.length,
      itemBuilder: (context, index) {
        final bankName = _groupedTransactions.keys.elementAt(index);
        final transactions = _groupedTransactions[bankName]!;
        
        return ExpansionTile(
          title: Row(
            children: [
              Text(
                bankName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transactions.length}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          initiallyExpanded: index == 0, // Expand the first bank by default
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, tIndex) {
                final transaction = transactions[tIndex];
                return _buildTransactionTile(transaction);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          transaction.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(transaction.date)),
            if (transaction.category != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(transaction.category),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      transaction.category!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  if (transaction.subcategory != null) ...[
                    const Text(' > ', style: TextStyle(fontSize: 12)),
                    Text(transaction.subcategory!, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.amount >= 0 ? Colors.green : Colors.red,
          ),
        ),
        onTap: () => _showCategorySelectionDialog(transaction),
        onLongPress: () => _showDeleteConfirmationDialog(transaction),
      ),
    );
  }
  
  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.grey;
    
    final Map<String, Color> categoryColors = {
      'Income': Colors.green,
      'Lifestyle': Colors.purple,
      'Fundamentals': Colors.blue,
      'Uncategorized': Colors.grey,
    };
    
    return categoryColors[category] ?? Colors.orange;
  }
} 