import 'package:json_annotation/json_annotation.dart';

part 'category_mapping.g.dart';

@JsonSerializable()
class CategoryMapping {
  final String keyword; // The keyword to match in transaction descriptions
  final String category; // Main category
  final String subcategory; // Subcategory
  
  // Optional fields for more advanced matching
  final bool caseSensitive; // Whether matching should be case-sensitive
  final bool exactMatch; // Whether to require an exact match or just containment

  CategoryMapping({
    required this.keyword,
    required this.category,
    required this.subcategory,
    this.caseSensitive = false,
    this.exactMatch = false,
  });

  // Connect the generated functions
  factory CategoryMapping.fromJson(Map<String, dynamic> json) => _$CategoryMappingFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryMappingToJson(this);
  
  // Check if this mapping matches a given transaction description
  bool matchesDescription(String description, {String? otherData}) {
    // Prepare the keyword and strings to check based on case sensitivity
    String keywordToMatch = caseSensitive ? keyword : keyword.toLowerCase();
    String descriptionToCheck = caseSensitive ? description : description.toLowerCase();
    String? otherDataToCheck = otherData != null ? 
        (caseSensitive ? otherData : otherData.toLowerCase()) : null;
    
    // Check if the keyword matches the description
    bool matchesDesc = exactMatch 
        ? descriptionToCheck == keywordToMatch
        : descriptionToCheck.contains(keywordToMatch);
    
    // If already matches the description, no need to check otherData
    if (matchesDesc) return true;
    
    // If otherData is provided, check if the keyword matches it
    if (otherDataToCheck != null && otherDataToCheck.isNotEmpty && otherDataToCheck != "none") {
      return exactMatch 
          ? otherDataToCheck == keywordToMatch
          : otherDataToCheck.contains(keywordToMatch);
    }
    
    // No match found in either field
    return false;
  }
}

@JsonSerializable()
class CategoryList {
  List<String> categories; // List of all main categories
  Map<String, List<String>> subcategories; // Map of category to its subcategories
  
  CategoryList({
    required this.categories,
    required this.subcategories,
  });
  
  // Connect the generated functions
  factory CategoryList.fromJson(Map<String, dynamic> json) => _$CategoryListFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryListToJson(this);
  
  // Helper to get default category list
  factory CategoryList.getDefault() {
    return CategoryList(
      categories: [
        'Income',
        'Fundamentals',
        'Lifestyle',
        'Discretionary',
        'Investments',
        'unknown'
      ],
      subcategories: {
        'Income': ['Salary', 'Bonus', 'Interest', 'Dividends', 'Other'],
        'Fundamentals': ['Rent', 'Utilities', 'Grocery', 'Transport', 'Healthcare', 'Insurance'],
        'Lifestyle': ['Dining', 'Entertainment', 'Shopping', 'Travel', 'Subscriptions'],
        'Discretionary': ['Gifts', 'Donations', 'Luxury', 'Personal Care'],
        'Investments': ['Stocks', 'Bonds', 'Real Estate', 'Retirement', 'Savings'],
        'unknown': ['uncategorized'],
      },
    );
  }
} 