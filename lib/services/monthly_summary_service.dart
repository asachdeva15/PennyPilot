import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/monthly_summary.dart';
import '../repositories/transaction_repository.dart';

class MonthlyTransactionSummaryService {
  static const String _storageKey = 'monthly_summaries';
  final TransactionRepository _transactionRepository;

  MonthlyTransactionSummaryService({
    required TransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  // Generate a summary for a specific month and year
  Future<MonthlyTransactionSummary> generateMonthlySummary(int year, int month) async {
    final allTransactions = await _transactionRepository.getAllTransactions();
    return MonthlyTransactionSummary.generateFromTransactions(year, month, allTransactions);
  }

  // Get all monthly summaries from storage
  Future<List<MonthlyTransactionSummary>> getAllMonthlySummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? summariesJson = prefs.getString(_storageKey);
      
      if (summariesJson == null || summariesJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(summariesJson);
      return decoded
          .map((item) => MonthlyTransactionSummary.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error retrieving monthly summaries: $e');
      return [];
    }
  }

  // Save a monthly summary to storage
  Future<bool> saveMonthlySummary(MonthlyTransactionSummary summary) async {
    try {
      final summaries = await getAllMonthlySummaries();
      
      // Remove existing summary for the same month if it exists
      summaries.removeWhere(
        (s) => s.year == summary.year && s.month == summary.month,
      );
      
      // Add the new summary
      summaries.add(summary);
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final encodedSummaries = jsonEncode(
        summaries.map((s) => s.toJson()).toList(),
      );
      
      return await prefs.setString(_storageKey, encodedSummaries);
    } catch (e) {
      debugPrint('Error saving monthly summary: $e');
      return false;
    }
  }

  // Generate and save summaries for all months with transactions
  Future<bool> generateAndSaveAllMonthlySummaries() async {
    try {
      final allTransactions = await _transactionRepository.getAllTransactions();
      
      // Get unique year-month combinations
      final Set<String> yearMonthKeys = {};
      for (final transaction in allTransactions) {
        final year = transaction.date.year;
        final month = transaction.date.month;
        yearMonthKeys.add('$year-$month');
      }
      
      // Generate summaries for each unique year-month
      for (final key in yearMonthKeys) {
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        final summary = MonthlyTransactionSummary.generateFromTransactions(
          year, month, allTransactions,
        );
        
        await saveMonthlySummary(summary);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error generating all monthly summaries: $e');
      return false;
    }
  }

  // Get the summary for a specific month
  Future<MonthlyTransactionSummary?> getMonthlySummary(int year, int month) async {
    final summaries = await getAllMonthlySummaries();
    try {
      return summaries.firstWhere(
        (summary) => summary.year == year && summary.month == month,
      );
    } catch (e) {
      // Summary doesn't exist for this month
      return null;
    }
  }

  // Get summaries for the most recent months (up to count)
  Future<List<MonthlyTransactionSummary>> getRecentMonthlySummaries(int count) async {
    final summaries = await getAllMonthlySummaries();
    
    // Sort by year and month (descending)
    summaries.sort((a, b) {
      final yearComparison = b.year.compareTo(a.year);
      if (yearComparison != 0) return yearComparison;
      return b.month.compareTo(a.month);
    });
    
    // Return up to the requested count
    return summaries.take(count).toList();
  }
} 