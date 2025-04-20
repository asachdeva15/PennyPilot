import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'monthly_summary.g.dart';
part 'monthly_summary.freezed.dart';

/// Represents a summary of a month's financial data
@freezed
class MonthlySummary with _$MonthlySummary {
  const MonthlySummary._();
  
  const factory MonthlySummary({
    required int year,
    required int month,
    
    /// Total income for the month (positive values)
    @Default(0.0) double totalIncome,
    
    /// Total expenses for the month (positive values, although expenses are negative in transactions)
    @Default(0.0) double totalExpenses,
    
    /// Total savings for the month (income - expenses)
    @Default(0.0) double totalSavings,
    
    /// Total spending by category
    @Default({}) Map<String, double> categoryTotals,
    
    /// Number of transactions in this month
    @Default(0) int transactionCount,
  }) = _MonthlySummary;
  
  /// Create from JSON map
  factory MonthlySummary.fromJson(Map<String, dynamic> json) => 
      _$MonthlySummaryFromJson(json);
      
  /// Create an empty summary with zeros
  factory MonthlySummary.empty(int year, int month) => MonthlySummary(
    year: year,
    month: month,
  );
}

/// Extended MonthlyTransactionSummary class for UI display and summary data
class MonthlyTransactionSummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpenses;
  final double totalSavings;
  final Map<String, double> categoryBreakdown;
  final int transactionCount;
  final DateTime generatedAt;
  final List<TopExpenseCategory> topExpenseCategories;

  MonthlyTransactionSummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.categoryBreakdown,
    required this.transactionCount,
    required this.generatedAt,
    required this.topExpenseCategories,
  });

  /// Convert to MonthlySummary for data storage
  MonthlySummary toMonthlyData() {
    return MonthlySummary(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
      categoryTotals: Map<String, double>.from(categoryBreakdown),
      transactionCount: transactionCount,
    );
  }
  
  /// Create an empty summary with zeros
  factory MonthlyTransactionSummary.empty(int year, int month) => MonthlyTransactionSummary(
    year: year,
    month: month,
    totalIncome: 0,
    totalExpenses: 0,
    totalSavings: 0,
    categoryBreakdown: {},
    transactionCount: 0,
    generatedAt: DateTime.now(),
    topExpenseCategories: [],
  );
  
  /// Create from JSON map
  factory MonthlyTransactionSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyTransactionSummary(
      year: json['year'] as int,
      month: json['month'] as int,
      totalIncome: json['totalIncome'] as double,
      totalExpenses: json['totalExpenses'] as double,
      totalSavings: json['totalSavings'] as double,
      categoryBreakdown: Map<String, double>.from(json['categoryBreakdown'] as Map),
      transactionCount: json['transactionCount'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      topExpenseCategories: (json['topExpenseCategories'] as List)
          .map((e) => TopExpenseCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalSavings': totalSavings,
      'categoryBreakdown': categoryBreakdown,
      'transactionCount': transactionCount,
      'generatedAt': generatedAt.toIso8601String(),
      'topExpenseCategories': topExpenseCategories.map((e) => e.toJson()).toList(),
    };
  }
}

/// We're not using freezed for now to make the tests pass
class TopExpenseCategory {
  final String category;
  final String? subcategory;
  final double amount;
  final double percentageOfTotal;

  const TopExpenseCategory({
    required this.category,
    this.subcategory,
    required this.amount,
    required this.percentageOfTotal,
  });

  factory TopExpenseCategory.fromJson(Map<String, dynamic> json) {
    return TopExpenseCategory(
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      amount: json['amount'] as double,
      percentageOfTotal: json['percentageOfTotal'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'percentageOfTotal': percentageOfTotal,
    };
  }
} 