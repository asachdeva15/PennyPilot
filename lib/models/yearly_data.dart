import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'monthly_data.dart';
import 'yearly_summary.dart';

part 'yearly_data.g.dart';
part 'yearly_data.freezed.dart';

/// Represents a full year of financial data including monthly breakdowns and yearly summary
@freezed
class YearlyData with _$YearlyData {
  const YearlyData._();
  
  const factory YearlyData({
    required int year,
    
    /// Monthly data indexed by month number (1-12)
    @Default({}) Map<int, MonthlyData> months,
    
    /// Yearly summary data containing aggregated financial metrics
    required YearlySummary summary,
  }) = _YearlyData;
  
  /// Create from JSON map
  factory YearlyData.fromJson(Map<String, dynamic> json) => 
      _$YearlyDataFromJson(json);
      
  /// Create an empty year structure with default summary
  factory YearlyData.empty(int year) => YearlyData(
    year: year,
    months: {},
    summary: YearlySummary.empty(year),
  );
  
  /// Gets a specific month's data, returns empty data if month doesn't exist
  MonthlyData getMonth(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    
    return months[month] ?? MonthlyData.empty(year, month);
  }
  
  /// Updates a specific month's data and recalculates yearly summary
  YearlyData updateMonth(int month, MonthlyData monthData) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    
    final updatedMonths = Map<int, MonthlyData>.from(months);
    updatedMonths[month] = monthData;
    
    // Recalculate yearly summary
    return recalculateSummary(updatedMonths);
  }
  
  /// Recalculates the yearly summary based on all months' data
  YearlyData recalculateSummary(Map<int, MonthlyData> monthsData) {
    // Initialize with zeros
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalSavings = 0;
    Map<String, double> categoryTotals = {};
    
    // Aggregate data from all months
    monthsData.forEach((_, monthData) {
      totalIncome += monthData.summary.totalIncome;
      totalExpenses += monthData.summary.totalExpenses;
      totalSavings += monthData.summary.totalSavings;
      
      // Aggregate category data
      monthData.summary.categoryTotals.forEach((category, amount) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      });
    });
    
    // Create updated yearly summary
    final updatedSummary = summary.copyWith(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
      categoryTotals: categoryTotals,
    );
    
    return copyWith(
      months: monthsData,
      summary: updatedSummary,
    );
  }
} 