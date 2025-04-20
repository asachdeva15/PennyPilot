import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_mapping.dart';
import '../services/file_service.dart';

class CategoryMappingNotifier extends StateNotifier<List<CategoryMapping>> {
  final FileService _fileService;
  
  CategoryMappingNotifier(this._fileService) : super([]) {
    _loadCategoryMappings();
  }
  
  Future<void> _loadCategoryMappings() async {
    try {
      final mappings = await _fileService.loadAllCategoryMappings();
      state = mappings;
    } catch (e) {
      debugPrint('Error loading category mappings: $e');
    }
  }
  
  Future<bool> addMapping(String keyword, String category, String subcategory, 
      {bool caseSensitive = false, bool exactMatch = false}) async {
    try {
      // Check if mapping with this keyword already exists
      final existingIndex = state.indexWhere((m) => m.keyword == keyword);
      if (existingIndex >= 0) {
        // Overwrite existing mapping
        return await updateMapping(existingIndex, keyword, category, subcategory,
            caseSensitive: caseSensitive, exactMatch: exactMatch);
      }
      
      // Create new mapping
      final mapping = CategoryMapping(
        keyword: keyword,
        category: category,
        subcategory: subcategory,
        caseSensitive: caseSensitive,
        exactMatch: exactMatch,
      );
      
      // Save to file service - now returns a boolean
      final success = await _fileService.saveCategoryMapping(mapping);
      
      if (success) {
        // Update state only if save was successful
        state = [...state, mapping];
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error adding category mapping: $e');
      return false;
    }
  }
  
  Future<bool> updateMapping(int index, String keyword, String category, String subcategory, 
      {bool caseSensitive = false, bool exactMatch = false}) async {
    try {
      if (index < 0 || index >= state.length) {
        return false;
      }
      
      // Get old mapping for filename
      final oldKeyword = state[index].keyword;
      
      // Create new mapping
      final mapping = CategoryMapping(
        keyword: keyword,
        category: category,
        subcategory: subcategory,
        caseSensitive: caseSensitive,
        exactMatch: exactMatch,
      );
      
      // If keyword changed, delete old file
      if (oldKeyword != keyword) {
        await deleteMapping(index, reload: false);
      }
      
      // Save to file service - now returns a boolean
      final success = await _fileService.saveCategoryMapping(mapping);
      
      if (success) {
        // Update state only if save was successful
        final updatedMappings = List<CategoryMapping>.from(state);
        updatedMappings[index] = mapping;
        state = updatedMappings;
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error updating category mapping: $e');
      return false;
    }
  }
  
  Future<bool> deleteMapping(int index, {bool reload = true}) async {
    try {
      if (index < 0 || index >= state.length) {
        return false;
      }
      
      // Get the mapping to delete
      final mapping = state[index];
      
      // Delete from file service - now returns a boolean
      final success = await _fileService.deleteCategoryMapping(mapping.keyword);
      
      if (success) {
        // Update state only if delete was successful
        final updatedMappings = List<CategoryMapping>.from(state);
        updatedMappings.removeAt(index);
        state = updatedMappings;
        
        // Reload the mappings if required
        if (reload) {
          await _loadCategoryMappings();
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting category mapping: $e');
      return false;
    }
  }
  
  List<CategoryMapping> getMappingsForCategory(String category) {
    return state.where((mapping) => mapping.category == category).toList();
  }
  
  List<CategoryMapping> getMappingsForSubcategory(String category, String subcategory) {
    return state.where((mapping) => 
      mapping.category == category && mapping.subcategory == subcategory
    ).toList();
  }
  
  Map<String, List<CategoryMapping>> getMappingsByCategory() {
    final map = <String, List<CategoryMapping>>{};
    
    for (final mapping in state) {
      if (!map.containsKey(mapping.category)) {
        map[mapping.category] = [];
      }
      map[mapping.category]!.add(mapping);
    }
    
    return map;
  }
  
  Future<void> refreshMappings() async {
    await _loadCategoryMappings();
  }
}

final categoryMappingProvider = StateNotifierProvider<CategoryMappingNotifier, List<CategoryMapping>>((ref) {
  final fileService = FileService();
  return CategoryMappingNotifier(fileService);
}); 