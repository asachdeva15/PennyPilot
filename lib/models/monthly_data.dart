import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'transaction.dart';
import 'monthly_summary.dart';

part 'monthly_data.g.dart';
part 'monthly_data.freezed.dart';

/// Represents a month of financial data including transactions and summary
@freezed
class MonthlyData with _$MonthlyData {
  const MonthlyData._();
  
  const factory MonthlyData({
    required int year,
    required int month,
    
    /// List of all transactions for this month
    @Default([]) List<Transaction> transactions,
    
    /// Summary data for this month
    required MonthlySummary summary,
  }) = _MonthlyData;
  
  /// Create from JSON map
  factory MonthlyData.fromJson(Map<String, dynamic> json) => 
      _$MonthlyDataFromJson(json);
  
  /// Create an empty month structure
  factory MonthlyData.empty(int year, int month) => MonthlyData(
    year: year,
    month: month,
    transactions: [],
    summary: MonthlySummary.empty(year, month),
  );
  
  /// Add a transaction and update the monthly summary
  MonthlyData addTransaction(Transaction transaction) {
    final updatedTransactions = List<Transaction>.from(transactions)
      ..add(transaction);
    return updateTransactions(updatedTransactions);
  }
  
  /// Update multiple transactions at once and recalculate summary
  MonthlyData updateTransactions(List<Transaction> updatedTransactions) {
    return copyWith(
      transactions: updatedTransactions,
      summary: _calculateSummary(updatedTransactions),
    );
  }
  
  /// Calculate summary statistics from transactions
  MonthlySummary _calculateSummary(List<Transaction> transactions) {
    // Initialize with zeros
    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categoryTotals = {};
    
    // Process each transaction
    for (final transaction in transactions) {
      final amount = transaction.amount;
      
      // Income is positive, expenses are negative
      if (amount > 0) {
        totalIncome += amount;
      } else {
        totalExpenses += amount.abs();
      }
      
      // Group by category
      final category = transaction.category ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + 
          (amount < 0 ? amount.abs() : 0); // Only expense categories
    }
    
    // Calculate savings (income - expenses)
    final totalSavings = totalIncome - totalExpenses;
    
    return summary.copyWith(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
      categoryTotals: categoryTotals,
    );
  }
} 