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