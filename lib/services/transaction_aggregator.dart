import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/monthly_summary.dart';
import '../repositories/summary_repository.dart';

class TransactionAggregator {
  final SummaryRepository _summaryRepository;

  TransactionAggregator(this._summaryRepository);

  /// Aggregates transactions by month and generates monthly summaries
  Future<List<MonthlyTransactionSummary>> aggregateTransactions(List<Transaction> transactions) async {
    // Group transactions by year and month
    final Map<String, List<Transaction>> groupedTransactions = {};
    
    for (final transaction in transactions) {
      final key = '${transaction.date.year}-${transaction.date.month}';
      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = [];
      }
      groupedTransactions[key]!.add(transaction);
    }

    final List<MonthlyTransactionSummary> summaries = [];

    // Generate summary for each month
    for (final entry in groupedTransactions.entries) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      final summary = await generateMonthlySummary(year, month, entry.value);
      summaries.add(summary);
      
      // Save summary to persistent storage
      await _summaryRepository.saveSummary(summary);
    }

    // Sort summaries by date, newest first
    summaries.sort((a, b) {
      final dateComparison = b.year.compareTo(a.year);
      if (dateComparison != 0) return dateComparison;
      return b.month.compareTo(a.month);
    });

    return summaries;
  }

  /// Generate a summary for a specific month from a list of transactions
  Future<MonthlyTransactionSummary> generateMonthlySummary(
      int year, int month, List<Transaction> transactions) async {
    
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};

    // Calculate totals
    for (final transaction in transactions) {
      final amount = transaction.amount;
      
      if (amount >= 0) {
        totalIncome += amount;
      } else {
        totalExpense += amount.abs();
      }

      if (transaction.category != null) {
        final category = transaction.category!;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount.abs();
      }
    }

    // Generate top categories by expense
    final List<CategoryBreakdown> topCategories = [];
    categoryTotals.forEach((category, amount) {
      if (amount > 0) {
        final percentage = amount / (totalExpense > 0 ? totalExpense : 1) * 100;
        topCategories.add(CategoryBreakdown(
          category: category,
          amount: amount,
          percentage: percentage,
        ));
      }
    });

    // Sort categories by amount (descending)
    topCategories.sort((a, b) => b.amount.compareTo(a.amount));

    // Take top 5 categories
    final limitedTopCategories = topCategories.take(5).toList();

    return MonthlyTransactionSummary(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categoryTotals: categoryTotals,
      topCategories: limitedTopCategories,
      generatedAt: DateTime.now(),
    );
  }

  /// Regenerates the summary for a specific month
  Future<MonthlyTransactionSummary?> regenerateSummaryForMonth(
      int year, int month, List<Transaction> transactions) async {
    
    // Filter transactions for the specified month
    final List<Transaction> monthTransactions = transactions.where((t) => 
      t.date.year == year && t.date.month == month
    ).toList();
    
    if (monthTransactions.isEmpty) {
      return null;
    }

    final summary = await generateMonthlySummary(year, month, monthTransactions);
    await _summaryRepository.saveSummary(summary);
    return summary;
  }
} 