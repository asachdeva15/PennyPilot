import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

/// Service for aggregating transactions by month
class TransactionAggregatorService {
  /// Groups transactions by year and month
  /// 
  /// Returns a Map where:
  /// - Key: String in format "YYYY-MM" (e.g., "2023-04")
  /// - Value: List of transactions for that month
  Map<String, List<Transaction>> groupTransactionsByMonth(List<Transaction> transactions) {
    final Map<String, List<Transaction>> groupedTransactions = {};
    
    for (final transaction in transactions) {
      final date = transaction.date;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = [];
      }
      
      groupedTransactions[key]!.add(transaction);
    }
    
    return groupedTransactions;
  }
  
  /// Gets a sorted list of month keys (YYYY-MM) from newest to oldest
  List<String> getSortedMonthKeys(Map<String, List<Transaction>> groupedTransactions) {
    final keys = groupedTransactions.keys.toList();
    
    // Sort keys in descending order (newest first)
    keys.sort((a, b) => b.compareTo(a));
    
    return keys;
  }
  
  /// Gets transactions for a specific year and month
  List<Transaction> getTransactionsForMonth(
    List<Transaction> allTransactions,
    int year,
    int month
  ) {
    return allTransactions.where((transaction) {
      final date = transaction.date;
      return date.year == year && date.month == month;
    }).toList();
  }
} 