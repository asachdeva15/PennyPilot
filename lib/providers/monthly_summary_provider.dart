/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_summary.dart';
import '../models/transaction.dart';
import 'transaction_provider.dart';

/// Provides access to monthly transaction summaries
class MonthlySummaryProvider extends StateNotifier<List<MonthlyTransactionSummary>> {
  final TransactionProvider _transactionProvider;
  
  MonthlySummaryProvider(this._transactionProvider) : super([]);

  /// Generates monthly summaries for all transactions
  Future<void> generateMonthlySummaries() async {
    final transactions = await _transactionProvider.getTransactions();
    final summaries = _generateSummariesFromTransactions(transactions);
    state = summaries;
  }

  /// Gets the monthly summary for a specific year and month
  MonthlyTransactionSummary? getSummaryForMonth(int year, int month) {
    return state.firstWhere(
      (summary) => summary.year == year && summary.month == month,
      orElse: () => _generateEmptySummary(year, month),
    );
  }

  /// Generate summaries from transactions
  List<MonthlyTransactionSummary> _generateSummariesFromTransactions(List<Transaction> transactions) {
    // Group transactions by year and month
    final groupedTransactions = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final date = transaction.date;
      final key = '${date.year}-${date.month}';
      
      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = [];
      }
      
      groupedTransactions[key]!.add(transaction);
    }
    
    // Generate summary for each month
    final summaries = <MonthlyTransactionSummary>[];
    
    groupedTransactions.forEach((key, monthTransactions) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      // Calculate totals
      double totalIncome = 0;
      double totalExpenses = 0;
      final categoryBreakdown = <String, double>{};
      
      for (final transaction in monthTransactions) {
        final amount = transaction.amount;
        
        if (amount > 0) {
          totalIncome += amount;
        } else {
          totalExpenses += amount.abs();
          
          // Update category breakdown
          final category = transaction.category ?? 'Uncategorized';
          categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + amount.abs();
        }
      }
      
      // Generate top expense categories
      final topCategories = <TopExpenseCategory>[];
      categoryBreakdown.forEach((category, amount) {
        final percentageOfTotal = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
        topCategories.add(
          TopExpenseCategory(
            category: category,
            amount: amount,
            percentageOfTotal: percentageOfTotal,
          ),
        );
      });
      
      // Sort by amount (descending)
      topCategories.sort((a, b) => b.amount.compareTo(a.amount));
      
      // Create summary
      final summary = MonthlyTransactionSummary(
        year: year,
        month: month,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netSavings: totalIncome - totalExpenses,
        categoryBreakdown: categoryBreakdown,
        topExpenseCategories: topCategories.take(5).toList(), // Top 5 categories
        generatedAt: DateTime.now(),
      );
      
      summaries.add(summary);
    });
    
    return summaries;
  }
  
  /// Creates an empty summary for a month with no transactions
  MonthlyTransactionSummary _generateEmptySummary(int year, int month) {
    return MonthlyTransactionSummary(
      year: year,
      month: month,
      totalIncome: 0,
      totalExpenses: 0,
      netSavings: 0,
      categoryBreakdown: {},
      topExpenseCategories: [],
      generatedAt: DateTime.now(),
    );
  }
}

/// Provider for monthly summaries
final monthlySummaryProvider = StateNotifierProvider<MonthlySummaryProvider, List<MonthlyTransactionSummary>>((ref) {
  final transactionProvider = ref.read(transactionProvider.notifier);
  return MonthlySummaryProvider(transactionProvider);
});

/// Provider to get the summary for the current month
final currentMonthSummaryProvider = Provider<MonthlyTransactionSummary>((ref) {
  final summaries = ref.watch(monthlySummaryProvider);
  final now = DateTime.now();
  
  return summaries.firstWhere(
    (summary) => summary.year == now.year && summary.month == now.month,
    orElse: () => MonthlyTransactionSummary(
      year: now.year,
      month: now.month,
      totalIncome: 0,
      totalExpenses: 0,
      netSavings: 0,
      categoryBreakdown: {},
      topExpenseCategories: [],
      generatedAt: DateTime.now(),
    ),
  );
});
*/

// Temporary replacement that doesn't break the build
import 'package:flutter/material.dart';

// Temporary non-breaking implementation
class MonthlySummaryProvider extends ChangeNotifier {
  // To be implemented properly later
} 