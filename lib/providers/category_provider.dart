import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/category_mapping.dart';
import '../services/file_service.dart';

/// Manages the categories for the application, including loading from storage
/// and providing methods to add, modify and access categories.
class CategoryProvider extends StateNotifier<Map<String, Category>> {
  final FileService _fileService;
  CategoryList? _categoryList;

  CategoryProvider(this._fileService) : super({}) {
    _initializeCategories();
  }

  /// Initialize categories by loading the category list and mapping to Category objects
  Future<void> _initializeCategories() async {
    try {
      // Load the CategoryList from file service
      _categoryList = await _fileService.loadCategoryList();
      
      // Convert to a Map<String, Category> using predefined categories
      final predefinedCategories = Category.getPredefinedCategories();
      final Map<String, Category> categoriesMap = {};
      
      // Add main categories
      for (final categoryName in _categoryList!.categories) {
        if (predefinedCategories.containsKey(categoryName)) {
          categoriesMap[categoryName] = predefinedCategories[categoryName]!;
        } else {
          // Create a default category if not predefined
          categoriesMap[categoryName] = Category(
            name: categoryName,
            color: Colors.grey,
            icon: Icons.category,
          );
        }
        
        // Add subcategories
        final subcategories = _categoryList!.subcategories[categoryName] ?? [];
        for (final subcategoryName in subcategories) {
          final key = '$categoryName:$subcategoryName';
          if (predefinedCategories.containsKey(subcategoryName)) {
            categoriesMap[key] = predefinedCategories[subcategoryName]!;
          } else {
            // Create a default subcategory if not predefined
            categoriesMap[key] = Category(
              name: subcategoryName,
              parentCategory: categoryName,
              color: categoriesMap[categoryName]?.color ?? Colors.grey,
              icon: Icons.subcategory,
            );
          }
        }
      }
      
      // Update state with the loaded categories
      state = categoriesMap;
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Fallback to default predefined categories
      state = Category.getPredefinedCategories();
    }
  }

  /// Returns a list of all main categories (excluding subcategories)
  List<Category> getMainCategories() {
    return state.values.where((category) => category.parentCategory == null).toList();
  }

  /// Returns a list of subcategories for a specific main category
  List<Category> getSubcategories(String categoryName) {
    return state.values
        .where((category) => category.parentCategory == categoryName)
        .toList();
  }

  /// Gets a Category by its name and optional subcategory
  Category? getCategoryByName(String categoryName, [String? subcategoryName]) {
    if (subcategoryName != null) {
      final key = '$categoryName:$subcategoryName';
      return state[key] ?? state[subcategoryName];
    }
    return state[categoryName];
  }

  /// Adds a new category
  Future<void> addCategory(String categoryName) async {
    if (_categoryList != null && !_categoryList!.categories.contains(categoryName)) {
      _categoryList!.categories.add(categoryName);
      _categoryList!.subcategories[categoryName] = [];
      
      // Save the updated category list
      await _fileService.saveCategoryList(_categoryList!);
      
      // Create a new Category object
      final newCategory = Category(
        name: categoryName,
        color: Colors.grey, // Default color
        icon: Icons.category, // Default icon
      );
      
      // Update the state
      state = {
        ...state,
        categoryName: newCategory,
      };
    }
  }

  /// Adds a new subcategory to a main category
  Future<void> addSubcategory(String categoryName, String subcategoryName) async {
    if (_categoryList != null && 
        _categoryList!.categories.contains(categoryName) &&
        !(_categoryList!.subcategories[categoryName] ?? []).contains(subcategoryName)) {
      
      _categoryList!.subcategories[categoryName] ??= [];
      _categoryList!.subcategories[categoryName]!.add(subcategoryName);
      
      // Save the updated category list
      await _fileService.saveCategoryList(_categoryList!);
      
      // Get the parent category for color inheritance
      final parentCategory = state[categoryName];
      
      // Create a new Category object for the subcategory
      final newSubcategory = Category(
        name: subcategoryName,
        parentCategory: categoryName,
        color: parentCategory?.color ?? Colors.grey,
        icon: Icons.subcategory,
      );
      
      // Update the state
      state = {
        ...state,
        '$categoryName:$subcategoryName': newSubcategory,
      };
    }
  }

  /// Updates a category's display properties (color, icon)
  void updateCategoryDisplay(String categoryName, {Color? color, IconData? icon}) {
    final category = state[categoryName];
    if (category != null) {
      final updatedCategory = Category(
        name: category.name,
        parentCategory: category.parentCategory,
        color: color ?? category.color,
        icon: icon ?? category.icon,
      );
      
      // Update the state
      state = {
        ...state,
        categoryName: updatedCategory,
      };
    }
  }
}

/// Provider for accessing the CategoryProvider
final categoryProvider = StateNotifierProvider<CategoryProvider, Map<String, Category>>((ref) {
  final fileService = FileService();
  return CategoryProvider(fileService);
});

/// Provider that returns a list of main categories
final mainCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesMap = ref.watch(categoryProvider);
  return categoriesMap.values.where((category) => category.parentCategory == null).toList();
});

/// Provider that returns subcategories for a specific main category
final subcategoriesProvider = Provider.family<List<Category>, String>((ref, categoryName) {
  final categoriesMap = ref.watch(categoryProvider);
  return categoriesMap.values
      .where((category) => category.parentCategory == categoryName)
      .toList();
}); 