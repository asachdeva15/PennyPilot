import 'dart:convert';
import 'package:collection/collection.dart';
import 'monthly_summary.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yearly_summary.g.dart';
part 'yearly_summary.freezed.dart';

/// Represents a summary of a year's financial data
@freezed
class YearlySummary with _$YearlySummary {
  const YearlySummary._();
  
  const factory YearlySummary({
    required int year,
    
    /// Total income for the year (positive values)
    @Default(0.0) double totalIncome,
    
    /// Total expenses for the year (positive values, although expenses are negative in transactions)
    @Default(0.0) double totalExpenses,
    
    /// Total savings for the year (income - expenses)
    @Default(0.0) double totalSavings,
    
    /// Total spending by category for the year
    @Default({}) Map<String, double> categoryTotals,
    
    /// Number of transactions in this year
    @Default(0) int transactionCount,
    
    /// The last updated timestamp
    DateTime? lastUpdated,
  }) = _YearlySummary;
  
  /// Create from JSON map
  factory YearlySummary.fromJson(Map<String, dynamic> json) => 
      _$YearlySummaryFromJson(json);
      
  /// Create an empty summary with zeros
  factory YearlySummary.empty(int year) => YearlySummary(
    year: year,
    lastUpdated: DateTime.now(),
  );
  
  /// Calculate savings rate (if income is 0, returns 0)
  double get savingsRate => 
      totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0;
      
  /// Get top expense categories (sorted by amount descending)
  List<MapEntry<String, double>> get topExpenseCategories {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
  
  /// Get the category with the highest spending
  MapEntry<String, double>? get topExpenseCategory {
    if (categoryTotals.isEmpty) return null;
    return topExpenseCategories.first;
  }
}

/// Lightweight version of MonthlyTransactionSummary used in YearlySummary
class MonthlySummaryData {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final Map<String, double> categoryBreakdown;

  MonthlySummaryData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.categoryBreakdown,
  });

  factory MonthlySummaryData.fromJson(Map<String, dynamic> json) {
    return MonthlySummaryData(
      totalIncome: json['totalIncome'] as double,
      totalExpenses: json['totalExpenses'] as double,
      netSavings: json['netSavings'] as double,
      categoryBreakdown: Map<String, double>.from(json['categoryBreakdown'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netSavings': netSavings,
      'categoryBreakdown': categoryBreakdown,
    };
  }
} 