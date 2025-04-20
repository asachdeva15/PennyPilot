import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/category_mapping.dart';
import '../providers/category_provider.dart';
import '../services/file_service.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final FileService _fileService = FileService();
  CategoryList? _categoryList;
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _newSubcategoryController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubcategory;
  Color _selectedColor = Colors.grey;
  IconData _selectedIcon = Icons.category;
  
  bool _isLoading = true;
  
  // Available icons for selection
  final List<IconData> _availableIcons = [
    Icons.home, Icons.work, Icons.attach_money, Icons.shopping_cart,
    Icons.restaurant, Icons.flight, Icons.directions_car, Icons.fitness_center,
    Icons.school, Icons.medical_services, Icons.local_grocery_store,
    Icons.local_movies, Icons.sports_esports, Icons.category, Icons.format_list_bulleted,
    Icons.savings, Icons.account_balance, Icons.credit_card, Icons.receipt,
    Icons.receipt_long, Icons.account_balance_wallet, Icons.local_atm,
    Icons.money_off, Icons.payment, Icons.diamond, Icons.power, Icons.power_settings_new,
    Icons.water, Icons.local_phone, Icons.wifi, Icons.laptop, Icons.tv,
    Icons.sports, Icons.beach_access, Icons.hotel, Icons.house,
    Icons.apartment, Icons.business, Icons.store, Icons.local_mall,
    Icons.redeem, Icons.card_giftcard, Icons.pets, Icons.child_care
  ];
  
  // Available colors for selection
  final List<Color> _availableColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey,
  ];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  @override
  void dispose() {
    _newCategoryController.dispose();
    _newSubcategoryController.dispose();
    _keywordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Load categories from file service
      _categoryList = await _fileService.loadCategoryList();
      
      // Set initial selected category if available
      if (_categoryList != null && _categoryList!.categories.isNotEmpty) {
        _selectedCategory = _categoryList!.categories.first;
        
        // Set initial selected subcategory if available
        if (_categoryList!.subcategories[_selectedCategory]?.isNotEmpty ?? false) {
          _selectedSubcategory = _categoryList!.subcategories[_selectedCategory]!.first;
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _addCategory() async {
    if (_newCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name cannot be empty')),
      );
      return;
    }
    
    final categoryName = _newCategoryController.text.trim();
    
    try {
      // Check if category already exists
      if (_categoryList!.categories.contains(categoryName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category already exists')),
        );
        return;
      }
      
      // Add category to provider
      await ref.read(categoryProvider.notifier).addCategory(categoryName);
      
      // Reload categories
      await _loadCategories();
      
      setState(() {
        _selectedCategory = categoryName;
        _selectedSubcategory = null;
      });
      
      _newCategoryController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$categoryName" added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }
  
  Future<void> _addSubcategory() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }
    
    if (_newSubcategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory name cannot be empty')),
      );
      return;
    }
    
    final subcategoryName = _newSubcategoryController.text.trim();
    
    try {
      // Check if subcategory already exists
      if (_categoryList!.subcategories[_selectedCategory]?.contains(subcategoryName) ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory already exists')),
        );
        return;
      }
      
      // Add subcategory to provider
      await ref.read(categoryProvider.notifier).addSubcategory(_selectedCategory!, subcategoryName);
      
      // Reload categories
      await _loadCategories();
      
      setState(() {
        _selectedSubcategory = subcategoryName;
      });
      
      _newSubcategoryController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subcategory "$subcategoryName" added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding subcategory: $e')),
      );
    }
  }
  
  Future<void> _updateCategoryDisplay() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }
    
    try {
      // Update category display properties
      ref.read(categoryProvider.notifier).updateCategoryDisplay(
        _selectedCategory!,
        color: _selectedColor,
        icon: _selectedIcon,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category display updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating category display: $e')),
      );
    }
  }
  
  Future<void> _addCategoryMapping() async {
    if (_selectedCategory == null || _selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and subcategory')),
      );
      return;
    }
    
    if (_keywordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keyword cannot be empty')),
      );
      return;
    }
    
    final keyword = _keywordController.text.trim();
    
    try {
      // Create and save category mapping
      final mapping = CategoryMapping(
        keyword: keyword,
        category: _selectedCategory!,
        subcategory: _selectedSubcategory!,
      );
      
      final success = await _fileService.saveCategoryMapping(mapping);
      
      if (success) {
        _keywordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category mapping for "$keyword" added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save category mapping for "$keyword"')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category mapping: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: const Color(0xFFE68A00),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE68A00)))
        : _categoryList == null 
          ? const Center(child: Text('Error loading categories'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Subcategory Selection
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Category and Subcategory',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCategory,
                            items: _categoryList!.categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                _selectedSubcategory = null;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subcategory Dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Subcategory',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedSubcategory,
                            items: (_selectedCategory != null && 
                                   _categoryList!.subcategories.containsKey(_selectedCategory))
                              ? _categoryList!.subcategories[_selectedCategory]!.map((subcategory) {
                                  return DropdownMenuItem(
                                    value: subcategory,
                                    child: Text(subcategory),
                                  );
                                }).toList()
                              : [],
                            onChanged: (value) {
                              setState(() {
                                _selectedSubcategory = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add New Category
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Category',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _newCategoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addCategory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE68A00),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Add Category'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add New Subcategory
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Subcategory',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _newSubcategoryController,
                            decoration: const InputDecoration(
                              labelText: 'Subcategory Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addSubcategory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE68A00),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Add Subcategory'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Customize Category Appearance
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customize Category Appearance',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Current Selection Preview
                          if (_selectedCategory != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _selectedColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(_selectedIcon, color: _selectedColor, size: 30),
                                  const SizedBox(width: 16),
                                  Text(
                                    _selectedCategory!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: _selectedColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Color Selection
                          const Text(
                            'Select Color:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableColors.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedColor == color 
                                        ? Colors.black 
                                        : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Icon Selection
                          const Text(
                            'Select Icon:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableIcons.map((icon) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIcon = icon;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedIcon == icon 
                                        ? _selectedColor 
                                        : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      icon,
                                      color: _selectedIcon == icon 
                                        ? _selectedColor 
                                        : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateCategoryDisplay,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE68A00),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Update Appearance'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add Category Mapping
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Keyword Mapping',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Map transaction descriptions containing a keyword to the selected category and subcategory',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _keywordController,
                            decoration: const InputDecoration(
                              labelText: 'Keyword',
                              hintText: 'e.g., "Netflix", "Rent", "Salary"',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addCategoryMapping,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE68A00),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Add Mapping'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 