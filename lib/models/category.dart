import 'package:flutter/material.dart';

/// Represents a transaction category with associated attributes like color
class Category {
  final String name;
  final String? parentCategory;
  final Color color;
  final IconData icon;

  const Category({
    required this.name,
    this.parentCategory,
    required this.color,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      parentCategory: json['parentCategory'] as String?,
      color: Color(json['color'] as int),
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parentCategory': parentCategory,
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
    };
  }

  /// Returns a default category for uncategorized transactions
  static Category get uncategorized => Category(
    name: 'Uncategorized',
    color: Colors.grey,
    icon: Icons.help_outline,
  );

  /// Returns predefined categories with appropriate colors and icons
  static Map<String, Category> getPredefinedCategories() {
    return {
      'Income': Category(
        name: 'Income',
        color: Colors.green,
        icon: Icons.account_balance_wallet,
      ),
      'Salary': Category(
        name: 'Salary',
        parentCategory: 'Income',
        color: Colors.green.shade700,
        icon: Icons.work,
      ),
      'Bonus': Category(
        name: 'Bonus',
        parentCategory: 'Income',
        color: Colors.green.shade600,
        icon: Icons.star,
      ),
      'Interest': Category(
        name: 'Interest',
        parentCategory: 'Income',
        color: Colors.green.shade500,
        icon: Icons.attach_money,
      ),
      'Dividends': Category(
        name: 'Dividends',
        parentCategory: 'Income',
        color: Colors.green.shade400,
        icon: Icons.trending_up,
      ),
      'Other Income': Category(
        name: 'Other',
        parentCategory: 'Income',
        color: Colors.green.shade300,
        icon: Icons.add_circle_outline,
      ),
      
      'Fundamentals': Category(
        name: 'Fundamentals',
        color: Colors.blue,
        icon: Icons.home,
      ),
      'Rent': Category(
        name: 'Rent',
        parentCategory: 'Fundamentals',
        color: Colors.blue.shade700,
        icon: Icons.house,
      ),
      'Utilities': Category(
        name: 'Utilities',
        parentCategory: 'Fundamentals',
        color: Colors.blue.shade600,
        icon: Icons.power,
      ),
      'Grocery': Category(
        name: 'Grocery',
        parentCategory: 'Fundamentals',
        color: Colors.blue.shade500,
        icon: Icons.shopping_cart,
      ),
      'Transport': Category(
        name: 'Transport',
        parentCategory: 'Fundamentals',
        color: Colors.blue.shade400,
        icon: Icons.directions_car,
      ),
      'Healthcare': Category(
        name: 'Healthcare',
        parentCategory: 'Fundamentals',
        color: Colors.blue.shade300,
        icon: Icons.medical_services,
      ),
      'Insurance': Category(
        name: 'Insurance',
        parentCategory: 'Fundamentals',
        color: Colors.blue.shade200,
        icon: Icons.security,
      ),
      
      'Lifestyle': Category(
        name: 'Lifestyle',
        color: Colors.orange,
        icon: Icons.nightlife,
      ),
      'Dining': Category(
        name: 'Dining',
        parentCategory: 'Lifestyle',
        color: Colors.orange.shade700,
        icon: Icons.restaurant,
      ),
      'Entertainment': Category(
        name: 'Entertainment',
        parentCategory: 'Lifestyle',
        color: Colors.orange.shade600,
        icon: Icons.movie,
      ),
      'Shopping': Category(
        name: 'Shopping',
        parentCategory: 'Lifestyle',
        color: Colors.orange.shade500,
        icon: Icons.shopping_bag,
      ),
      'Travel': Category(
        name: 'Travel',
        parentCategory: 'Lifestyle',
        color: Colors.orange.shade400,
        icon: Icons.flight,
      ),
      'Subscriptions': Category(
        name: 'Subscriptions',
        parentCategory: 'Lifestyle',
        color: Colors.orange.shade300,
        icon: Icons.subscriptions,
      ),
      
      'Discretionary': Category(
        name: 'Discretionary',
        color: Colors.purple,
        icon: Icons.card_giftcard,
      ),
      'Gifts': Category(
        name: 'Gifts',
        parentCategory: 'Discretionary',
        color: Colors.purple.shade700,
        icon: Icons.redeem,
      ),
      'Donations': Category(
        name: 'Donations',
        parentCategory: 'Discretionary',
        color: Colors.purple.shade600,
        icon: Icons.volunteer_activism,
      ),
      'Luxury': Category(
        name: 'Luxury',
        parentCategory: 'Discretionary',
        color: Colors.purple.shade500,
        icon: Icons.diamond,
      ),
      'Personal Care': Category(
        name: 'Personal Care',
        parentCategory: 'Discretionary',
        color: Colors.purple.shade400,
        icon: Icons.spa,
      ),
      
      'Investments': Category(
        name: 'Investments',
        color: Colors.teal,
        icon: Icons.trending_up,
      ),
      'Stocks': Category(
        name: 'Stocks',
        parentCategory: 'Investments',
        color: Colors.teal.shade700,
        icon: Icons.show_chart,
      ),
      'Bonds': Category(
        name: 'Bonds',
        parentCategory: 'Investments',
        color: Colors.teal.shade600,
        icon: Icons.account_balance,
      ),
      'Real Estate': Category(
        name: 'Real Estate',
        parentCategory: 'Investments',
        color: Colors.teal.shade500,
        icon: Icons.business,
      ),
      'Retirement': Category(
        name: 'Retirement',
        parentCategory: 'Investments',
        color: Colors.teal.shade400,
        icon: Icons.savings,
      ),
      'Savings': Category(
        name: 'Savings',
        parentCategory: 'Investments',
        color: Colors.teal.shade300,
        icon: Icons.savings,
      ),
      
      'unknown': Category(
        name: 'Unknown',
        color: Colors.grey,
        icon: Icons.help_outline,
      ),
      'uncategorized': Category(
        name: 'Uncategorized',
        parentCategory: 'unknown',
        color: Colors.grey.shade400,
        icon: Icons.help,
      ),
    };
  }

  /// Gets the Category object based on the category name and optional subcategory name
  static Category getCategoryByName(String categoryName, [String? subcategoryName]) {
    final predefinedCategories = getPredefinedCategories();
    
    if (subcategoryName != null) {
      final fullName = '$categoryName: $subcategoryName';
      if (predefinedCategories.containsKey(subcategoryName)) {
        return predefinedCategories[subcategoryName]!;
      }
    }
    
    if (predefinedCategories.containsKey(categoryName)) {
      return predefinedCategories[categoryName]!;
    }
    
    return Category.uncategorized;
  }
} 