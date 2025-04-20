import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import 'transaction.dart';
import 'monthly_summary.dart';
import 'yearly_summary.dart';
import 'yearly_data.dart';
import 'monthly_data.dart';

part 'comprehensive_yearly_data.freezed.dart';
part 'comprehensive_yearly_data.g.dart';

/// Comprehensive data structure that combines yearly data and additional metadata
@freezed
class ComprehensiveYearlyData with _$ComprehensiveYearlyData {
  const ComprehensiveYearlyData._(); // Add a private constructor for getters
  
  const factory ComprehensiveYearlyData({
    required int year,
    required YearlyData yearlyData,
    required DateTime generatedAt,
  }) = _ComprehensiveYearlyData;

  factory ComprehensiveYearlyData.fromJson(Map<String, dynamic> json) => 
      _$ComprehensiveYearlyDataFromJson(json);
      
  /// Access the yearly summary from the yearlyData
  YearlySummary get yearlySummary => yearlyData.summary;

  /// Generates comprehensive yearly data from YearlyData
  static ComprehensiveYearlyData generateFromYearlyData(
    YearlyData yearlyData,
  ) {
    return ComprehensiveYearlyData(
      year: yearlyData.year,
      yearlyData: yearlyData,
      generatedAt: DateTime.now(),
    );
  }
  
  /// Generates comprehensive yearly data from transactions and summaries
  static ComprehensiveYearlyData generateFromTransactions(
    int year,
    List<Transaction> transactions,
    YearlySummary yearlySummary,
    List<MonthlyTransactionSummary> monthlySummaries,
  ) {
    // Filter transactions for this year
    final yearTransactions = transactions.where(
      (t) => t.date.year == year
    ).toList();
    
    // Build monthly data for each month
    final Map<int, MonthlyData> monthsData = {};
    
    // Group transactions by month
    final Map<int, List<Transaction>> transactionsByMonth = groupBy(
      yearTransactions, 
      (Transaction t) => t.date.month
    );
    
    // Create monthly data for each month with transactions
    for (final month in transactionsByMonth.keys) {
      // Find matching monthly summary or create empty one
      final matchingSummary = monthlySummaries.firstWhere(
        (s) => s.month == month,
        orElse: () => MonthlyTransactionSummary.empty(year, month),
      );
      
      // Create monthly data
      monthsData[month] = MonthlyData(
        year: year,
        month: month,
        transactions: transactionsByMonth[month]!,
        summary: matchingSummary.toMonthlyData(),
      );
    }
    
    // Create yearly data
    final yearlyData = YearlyData(
      year: year,
      months: monthsData,
      summary: yearlySummary,
    );
    
    return ComprehensiveYearlyData(
      year: year,
      yearlyData: yearlyData,
      generatedAt: DateTime.now(),
    );
  }
} 