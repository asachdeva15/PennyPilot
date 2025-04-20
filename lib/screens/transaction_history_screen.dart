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
  List<Transaction> _filteredTransactions = [];
  Map<String, List<Transaction>> _groupedTransactions = {};
  List<String> _categories = [];
  Map<String, List<String>> _subcategories = {};
  
  // Sorting and filtering options
  String _sortCriteria = 'date';
  bool _sortAscending = false;
  String? _filterCategory;
  String? _filterSubcategory;
  String? _filterBankName;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  double? _filterMinAmount;
  double? _filterMaxAmount;
  String? _searchQuery;
  
  // Grouping options
  String _groupBy = 'bank'; // 'bank', 'category', 'month', 'none'

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
      
      // Load categories and subcategories
      await _loadCategories();
      
      // Apply initial filtering and sorting
      _applyFiltersAndSort();
      
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
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Apply filters and sorting to the transactions
  void _applyFiltersAndSort() {
    // Start with all transactions
    _filteredTransactions = List.from(_allTransactions);
    
    // Apply category filter
    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.category == _filterCategory).toList();
    }
    
    // Apply subcategory filter
    if (_filterSubcategory != null && _filterSubcategory!.isNotEmpty) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.subcategory == _filterSubcategory).toList();
    }
    
    // Apply bank name filter
    if (_filterBankName != null && _filterBankName!.isNotEmpty) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.bankName == _filterBankName).toList();
    }
    
    // Apply date range filter
    if (_filterStartDate != null) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAtSameMomentAs(_filterStartDate!) || 
        t.date.isAfter(_filterStartDate!)).toList();
    }
    
    if (_filterEndDate != null) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.date.isAtSameMomentAs(_filterEndDate!) || 
        t.date.isBefore(_filterEndDate!)).toList();
    }
    
    // Apply amount range filter
    if (_filterMinAmount != null) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.amount >= _filterMinAmount!).toList();
    }
    
    if (_filterMaxAmount != null) {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.amount <= _filterMaxAmount!).toList();
    }
    
    // Apply search query filter
    if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.description.toLowerCase().contains(query) ||
        (t.notes?.toLowerCase().contains(query) ?? false) ||
        (t.otherData?.toLowerCase().contains(query) ?? false)).toList();
    }
    
    // Apply sorting
    _filteredTransactions.sort((a, b) {
      int result;
      
      switch (_sortCriteria) {
        case 'date':
          result = a.date.compareTo(b.date);
          break;
        case 'amount':
          result = a.amount.compareTo(b.amount);
          break;
        case 'description':
          result = a.description.compareTo(b.description);
          break;
        case 'category':
          final categoryA = a.category ?? '';
          final categoryB = b.category ?? '';
          result = categoryA.compareTo(categoryB);
          break;
        case 'bank':
          final bankA = a.bankName;
          final bankB = b.bankName;
          result = bankA.compareTo(bankB);
          break;
        default:
          result = a.date.compareTo(b.date);
      }
      
      return _sortAscending ? result : -result;
    });
    
    // Apply grouping
    _groupTransactions();
  }
  
  // Group transactions based on selected criteria
  void _groupTransactions() {
    _groupedTransactions = {};
    
    if (_groupBy == 'none') {
      // No grouping, put all under a single key
      _groupedTransactions['All Transactions'] = _filteredTransactions;
      return;
    }
    
    for (final transaction in _filteredTransactions) {
      String groupKey;
      
      switch (_groupBy) {
        case 'bank':
          groupKey = transaction.bankName;
          break;
        case 'category':
          groupKey = transaction.category ?? 'Uncategorized';
          break;
        case 'month':
          final monthYear = DateFormat('MMMM yyyy').format(transaction.date);
          groupKey = monthYear;
          break;
        default:
          groupKey = transaction.bankName;
      }
      
      if (!_groupedTransactions.containsKey(groupKey)) {
        _groupedTransactions[groupKey] = [];
      }
      
      _groupedTransactions[groupKey]!.add(transaction);
    }
  }
  
  // Reset all filters
  void _resetFilters() {
    setState(() {
      _filterCategory = null;
      _filterSubcategory = null;
      _filterBankName = null;
      _filterStartDate = null;
      _filterEndDate = null;
      _filterMinAmount = null;
      _filterMaxAmount = null;
      _searchQuery = null;
      _applyFiltersAndSort();
    });
  }

  // Show filter dialog
  void _showFilterDialog() {
    String? tempCategory = _filterCategory;
    String? tempSubcategory = _filterSubcategory;
    String? tempBankName = _filterBankName;
    DateTime? tempStartDate = _filterStartDate;
    DateTime? tempEndDate = _filterEndDate;
    
    // Get unique bank names from transactions
    final bankNames = _allTransactions
        .map((t) => t.bankName)
        .toSet()
        .toList();
    bankNames.sort();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Transactions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category dropdown
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: tempCategory,
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((category) => DropdownMenuItem<String?>(
                        value: category,
                        child: Text(category),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempCategory = value;
                        // Reset subcategory when category changes
                        tempSubcategory = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Subcategory dropdown (only enabled if category is selected)
                  const Text('Subcategory:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: tempSubcategory,
                    hint: const Text('All Subcategories'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Subcategories'),
                      ),
                      ...(tempCategory != null && _subcategories.containsKey(tempCategory!)
                          ? _subcategories[tempCategory!]!.map((subcategory) => DropdownMenuItem<String?>(
                              value: subcategory,
                              child: Text(subcategory),
                            ))
                          : []),
                    ],
                    onChanged: tempCategory == null
                        ? null
                        : (value) {
                            setDialogState(() {
                              tempSubcategory = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  
                  // Bank name dropdown
                  const Text('Bank:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: tempBankName,
                    hint: const Text('All Banks'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Banks'),
                      ),
                      ...bankNames.map((bank) => DropdownMenuItem<String?>(
                        value: bank,
                        child: Text(bank),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempBankName = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date range
                  const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            tempStartDate == null
                                ? 'Start Date'
                                : DateFormat('dd MMM yyyy').format(tempStartDate!),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                tempStartDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            tempEndDate == null
                                ? 'End Date'
                                : DateFormat('dd MMM yyyy').format(tempEndDate!),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempEndDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                tempEndDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
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
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterCategory = tempCategory;
                    _filterSubcategory = tempSubcategory;
                    _filterBankName = tempBankName;
                    _filterStartDate = tempStartDate;
                    _filterEndDate = tempEndDate;
                    _applyFiltersAndSort();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Show sort dialog
  void _showSortDialog() {
    String tempSortCriteria = _sortCriteria;
    bool tempSortAscending = _sortAscending;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Sort Transactions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sort by options
                const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Date'),
                  value: 'date',
                  groupValue: tempSortCriteria,
                  onChanged: (value) {
                    setDialogState(() {
                      tempSortCriteria = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Amount'),
                  value: 'amount',
                  groupValue: tempSortCriteria,
                  onChanged: (value) {
                    setDialogState(() {
                      tempSortCriteria = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Description'),
                  value: 'description',
                  groupValue: tempSortCriteria,
                  onChanged: (value) {
                    setDialogState(() {
                      tempSortCriteria = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Category'),
                  value: 'category',
                  groupValue: tempSortCriteria,
                  onChanged: (value) {
                    setDialogState(() {
                      tempSortCriteria = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Bank'),
                  value: 'bank',
                  groupValue: tempSortCriteria,
                  onChanged: (value) {
                    setDialogState(() {
                      tempSortCriteria = value!;
                    });
                  },
                ),
                
                const Divider(),
                
                // Sort direction
                Row(
                  children: [
                    Checkbox(
                      value: tempSortAscending,
                      onChanged: (value) {
                        setDialogState(() {
                          tempSortAscending = value!;
                        });
                      },
                    ),
                    const Text('Ascending order'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortCriteria = tempSortCriteria;
                    _sortAscending = tempSortAscending;
                    _applyFiltersAndSort();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Show group by dialog
  void _showGroupDialog() {
    String tempGroupBy = _groupBy;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Group Transactions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<String>(
                  title: const Text('By Bank'),
                  value: 'bank',
                  groupValue: tempGroupBy,
                  onChanged: (value) {
                    setDialogState(() {
                      tempGroupBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('By Category'),
                  value: 'category',
                  groupValue: tempGroupBy,
                  onChanged: (value) {
                    setDialogState(() {
                      tempGroupBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('By Month'),
                  value: 'month',
                  groupValue: tempGroupBy,
                  onChanged: (value) {
                    setDialogState(() {
                      tempGroupBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('No Grouping'),
                  value: 'none',
                  groupValue: tempGroupBy,
                  onChanged: (value) {
                    setDialogState(() {
                      tempGroupBy = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _groupBy = tempGroupBy;
                    _applyFiltersAndSort();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateTransaction(Transaction transaction, {String? category, String? subcategory, String? otherData}) async {
    try {
      // Create updated transaction
      final updatedTransaction = transaction.copyWith(
        category: category ?? transaction.category,
        subcategory: subcategory ?? transaction.subcategory,
        otherData: otherData ?? transaction.otherData,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFFE68A00),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.group_work),
            onPressed: _showGroupDialog,
            tooltip: 'Group',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = null;
                      _applyFiltersAndSort();
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),
          
          // Active filters display
          if (_filterCategory != null || _filterBankName != null || _filterStartDate != null || 
              _filterEndDate != null || _filterMinAmount != null || _filterMaxAmount != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    const Text('Active Filters:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (_filterCategory != null)
                            _buildFilterChip('Category: $_filterCategory'),
                          if (_filterSubcategory != null)
                            _buildFilterChip('Subcategory: $_filterSubcategory'),
                          if (_filterBankName != null)
                            _buildFilterChip('Bank: $_filterBankName'),
                          if (_filterStartDate != null)
                            _buildFilterChip('From: ${DateFormat('dd MMM yyyy').format(_filterStartDate!)}'),
                          if (_filterEndDate != null)
                            _buildFilterChip('To: ${DateFormat('dd MMM yyyy').format(_filterEndDate!)}'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Summary information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found: ${_filteredTransactions.length} transactions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${NumberFormat.currency(locale: 'de_DE', symbol: '€').format(_calculateTotal())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _calculateTotal() >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : _buildTransactionList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
  
  double _calculateTotal() {
    return _filteredTransactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  Widget _buildTransactionList() {
    if (_groupedTransactions.isEmpty) {
      return const Center(child: Text('No transactions match the filter criteria'));
    }
    
    return ListView.builder(
      itemCount: _groupedTransactions.length,
      itemBuilder: (context, index) {
        final groupName = _groupedTransactions.keys.elementAt(index);
        final transactions = _groupedTransactions[groupName]!;
        
        return ExpansionTile(
          title: Row(
            children: [
              Text(
                groupName,
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
              const Spacer(),
              Text(
                NumberFormat.currency(locale: 'de_DE', symbol: '€').format(
                  transactions.fold(0.0, (sum, tx) => sum + tx.amount)),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transactions.fold(0.0, (sum, tx) => sum + tx.amount) >= 0 
                      ? Colors.green 
                      : Colors.red,
                ),
              )
            ],
          ),
          initiallyExpanded: index == 0, // Expand the first group by default
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
            if (transaction.otherData != null && transaction.otherData!.isNotEmpty)
              Text(
                'Other: ${transaction.otherData}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'Other: NONE',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  void _showCategorySelectionDialog(Transaction transaction) {
    // Try to guess best category based on description
    String? suggestedCategory = _suggestCategoryForTransaction(transaction);
    
    String? selectedCategory = transaction.category ?? suggestedCategory;
    String? selectedSubcategory = transaction.subcategory;
    String? otherData = transaction.otherData;
    
    // For new category/subcategory input
    final TextEditingController newCategoryController = TextEditingController();
    final TextEditingController newSubcategoryController = TextEditingController();
    final TextEditingController otherDataController = TextEditingController(
      text: (transaction.otherData != null && transaction.otherData!.isNotEmpty) 
        ? transaction.otherData! 
        : "NONE"
    );
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
                    
                    // Other data field
                    TextField(
                      controller: otherDataController,
                      decoration: const InputDecoration(
                        labelText: 'Other Information',
                        hintText: 'Additional transaction data',
                      ),
                      readOnly: true,
                      style: TextStyle(
                        fontStyle: transaction.otherData != null && transaction.otherData!.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                        color: transaction.otherData != null && transaction.otherData!.isNotEmpty
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                    
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
                      otherData: otherDataController.text.trim() != "NONE" ? otherDataController.text.trim() : transaction.otherData,
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
            if (transaction.otherData != null && transaction.otherData!.isNotEmpty)
              Text('Other: ${transaction.otherData}')
            else
              Text(
                'Other: NONE',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
} 