import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_mapping.dart';
import '../providers/category_mapping_provider.dart';
import '../providers/category_provider.dart';

class CategoryMappingScreen extends ConsumerStatefulWidget {
  const CategoryMappingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryMappingScreen> createState() => _CategoryMappingScreenState();
}

class _CategoryMappingScreenState extends ConsumerState<CategoryMappingScreen> {
  String? _selectedCategory;
  
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String? _editCategory;
  String? _editSubcategory;
  bool _editCaseSensitive = false;
  bool _editExactMatch = false;
  
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh mappings on startup
      ref.read(categoryMappingProvider.notifier).refreshMappings();
    });
  }
  
  @override
  void dispose() {
    _keywordController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Show dialog to add or edit a mapping
  void _showMappingDialog([CategoryMapping? existingMapping, int? index]) {
    _keywordController.text = existingMapping?.keyword ?? '';
    _editCategory = existingMapping?.category;
    _editSubcategory = existingMapping?.subcategory;
    _editCaseSensitive = existingMapping?.caseSensitive ?? false;
    _editExactMatch = existingMapping?.exactMatch ?? false;
    
    final categoryList = CategoryList.getDefault();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingMapping == null ? 'Add New Mapping' : 'Edit Mapping'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      labelText: 'Keyword',
                      hintText: 'e.g., "Netflix", "Rent", "Salary"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _editCategory,
                    items: categoryList.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _editCategory = value;
                        _editSubcategory = null;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      border: OutlineInputBorder(),
                    ),
                    value: _editSubcategory,
                    items: (_editCategory != null && 
                           categoryList.subcategories.containsKey(_editCategory))
                      ? categoryList.subcategories[_editCategory]!.map((subcategory) {
                          return DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory),
                          );
                        }).toList()
                      : [],
                    onChanged: (value) {
                      setState(() {
                        _editSubcategory = value;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Case Sensitive'),
                    subtitle: const Text('Match exact case in transaction descriptions'),
                    value: _editCaseSensitive,
                    onChanged: (value) {
                      setState(() {
                        _editCaseSensitive = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Exact Match'),
                    subtitle: const Text('Match whole description instead of just containing keyword'),
                    value: _editExactMatch,
                    onChanged: (value) {
                      setState(() {
                        _editExactMatch = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_keywordController.text.trim().isEmpty ||
                      _editCategory == null ||
                      _editSubcategory == null) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }
                  
                  bool success;
                  
                  if (existingMapping == null) {
                    // Add new mapping
                    success = await ref.read(categoryMappingProvider.notifier).addMapping(
                      _keywordController.text.trim(),
                      _editCategory!,
                      _editSubcategory!,
                      caseSensitive: _editCaseSensitive,
                      exactMatch: _editExactMatch,
                    );
                  } else {
                    // Update existing mapping
                    success = await ref.read(categoryMappingProvider.notifier).updateMapping(
                      index!,
                      _keywordController.text.trim(),
                      _editCategory!,
                      _editSubcategory!,
                      caseSensitive: _editCaseSensitive,
                      exactMatch: _editExactMatch,
                    );
                  }
                  
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        existingMapping == null 
                          ? 'Mapping added successfully' 
                          : 'Mapping updated successfully'
                      )),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE68A00),
                ),
                child: Text(existingMapping == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final mappings = ref.watch(categoryMappingProvider);
    final categories = ref.watch(categoryProvider);
    
    // Filter mappings based on search query and selected category
    final filteredMappings = mappings.where((mapping) {
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty || 
        mapping.keyword.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        mapping.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        mapping.subcategory.toLowerCase().contains(_searchQuery.toLowerCase());
        
      // Apply category filter
      final matchesCategory = _selectedCategory == null || mapping.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    // Sort by category, then subcategory
    filteredMappings.sort((a, b) {
      int categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.subcategory.compareTo(b.subcategory);
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Mappings'),
        backgroundColor: const Color(0xFFE68A00),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(categoryMappingProvider.notifier).refreshMappings(),
            tooltip: 'Refresh Mappings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search mappings',
                      hintText: 'Search by keyword, category or subcategory',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Category filter dropdown
                DropdownButton<String?>(
                  hint: const Text('Filter by category'),
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...CategoryList.getDefault().categories.map((category) {
                      return DropdownMenuItem<String?>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Display number of mappings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredMappings.length} of ${mappings.length} mappings',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                  onPressed: () => _showMappingDialog(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Mapping list
          Expanded(
            child: mappings.isEmpty
              ? const Center(
                  child: Text(
                    'No category mappings found.\nAdd a new mapping to get started.',
                    textAlign: TextAlign.center,
                  ),
                )
              : filteredMappings.isEmpty 
                ? const Center(
                    child: Text(
                      'No mappings match your search criteria.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMappings.length,
                    itemBuilder: (context, index) {
                      final mapping = filteredMappings[index];
                      
                      // Get the real index in the full list for operations
                      final realIndex = mappings.indexWhere((m) => m.keyword == mapping.keyword);
                      
                      // Get category color and icon
                      final categoryObj = categories[mapping.category];
                      final subcategoryKey = '${mapping.category}:${mapping.subcategory}';
                      final subcategoryObj = categories[subcategoryKey] ?? categories[mapping.subcategory];
                      
                      final color = subcategoryObj?.color ?? categoryObj?.color ?? Colors.grey;
                      final icon = subcategoryObj?.icon ?? categoryObj?.icon ?? Icons.label;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(icon, color: color),
                          ),
                          title: Text(
                            mapping.keyword,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${mapping.category} > ${mapping.subcategory}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (mapping.caseSensitive || mapping.exactMatch)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Wrap(
                                    spacing: 4,
                                    children: [
                                      if (mapping.caseSensitive)
                                        Tooltip(
                                          message: 'Case sensitive',
                                          child: Chip(
                                            label: const Text('Aa', style: TextStyle(fontSize: 10)),
                                            backgroundColor: Colors.blue.shade100,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                          ),
                                        ),
                                      if (mapping.exactMatch)
                                        Tooltip(
                                          message: 'Exact match',
                                          child: Chip(
                                            label: const Text('="', style: TextStyle(fontSize: 10)),
                                            backgroundColor: Colors.purple.shade100,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showMappingDialog(mapping, realIndex),
                                tooltip: 'Edit Mapping',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Show confirmation dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Mapping'),
                                      content: Text(
                                        'Are you sure you want to delete the mapping for "${mapping.keyword}"?'
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            
                                            final success = await ref.read(categoryMappingProvider.notifier)
                                                .deleteMapping(realIndex);
                                            
                                            if (success && mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Mapping deleted successfully')),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'Delete Mapping',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMappingDialog(),
        backgroundColor: const Color(0xFFE68A00),
        child: const Icon(Icons.add),
        tooltip: 'Add New Mapping',
      ),
    );
  }
} 