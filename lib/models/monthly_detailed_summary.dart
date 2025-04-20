import 'dart:convert';
import 'transaction.dart';
import 'monthly_summary.dart';

/// A detailed monthly summary that includes both aggregated summary data
/// and the full list of transactions for the month
class MonthlyDetailedSummary {
  final int year;
  final int month;
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final Map<String, double> categoryBreakdown;
  final List<TopExpenseCategory> topExpenseCategories;
  final DateTime generatedAt;

  MonthlyDetailedSummary({
    required this.year,
    required this.month,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.categoryBreakdown,
    required this.topExpenseCategories,
    required this.generatedAt,
  });

  /// Create a detailed summary from a list of transactions for a specific month
  factory MonthlyDetailedSummary.fromTransactions(
    List<Transaction> transactions,
    int year,
    int month,
  ) {
    // Filter transactions for the specified month
    final monthlyTransactions = transactions.where((transaction) {
      final date = transaction.date;
      return date.year == year && date.month == month;
    }).toList();

    // Calculate total income (positive transactions)
    final totalIncome = monthlyTransactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate total expenses (negative transactions)
    final totalExpenses = monthlyTransactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Calculate net savings
    final netSavings = totalIncome - totalExpenses;

    // Group by category and calculate totals
    final categoryMap = <String, double>{};
    for (final transaction in monthlyTransactions) {
      if (transaction.amount < 0) {
        final category = transaction.category ?? 'Uncategorized';
        categoryMap[category] = (categoryMap[category] ?? 0) + transaction.amount.abs();
      }
    }

    // Generate top expense categories
    final topCategories = <TopExpenseCategory>[];
    categoryMap.forEach((category, amount) {
      final percentageOfTotal = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
      
      topCategories.add(
        TopExpenseCategory(
          category: category,
          subcategory: null, // We don't aggregate by subcategory here
          amount: amount,
          percentageOfTotal: percentageOfTotal,
        ),
      );
    });

    // Sort by amount (descending)
    topCategories.sort((a, b) => b.amount.compareTo(a.amount));

    // Take top 5 categories
    final topExpenseCategories = topCategories.take(5).toList();

    return MonthlyDetailedSummary(
      year: year,
      month: month,
      transactions: monthlyTransactions,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netSavings: netSavings,
      categoryBreakdown: categoryMap,
      topExpenseCategories: topExpenseCategories,
      generatedAt: DateTime.now(),
    );
  }

  /// Convert this detailed summary to a summary-only version
  MonthlyTransactionSummary toSummary() {
    return MonthlyTransactionSummary(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: netSavings,
      categoryBreakdown: categoryBreakdown,
      transactionCount: transactions.length,
      generatedAt: generatedAt,
      topExpenseCategories: topExpenseCategories,
    );
  }

  factory MonthlyDetailedSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyDetailedSummary(
      year: json['year'] as int,
      month: json['month'] as int,
      transactions: (json['transactions'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalIncome: json['totalIncome'] as double,
      totalExpenses: json['totalExpenses'] as double,
      netSavings: json['netSavings'] as double,
      categoryBreakdown: Map<String, double>.from(json['categoryBreakdown'] as Map),
      topExpenseCategories: (json['topExpenseCategories'] as List)
          .map((e) => TopExpenseCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netSavings': netSavings,
      'categoryBreakdown': categoryBreakdown,
      'topExpenseCategories': topExpenseCategories.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
} 