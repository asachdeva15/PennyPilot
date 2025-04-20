import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/monthly_summary.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/summary_repository.dart';

class SummaryService {
  final TransactionRepository _transactionRepository;
  final SummaryRepository _summaryRepository;

  SummaryService({
    required TransactionRepository transactionRepository,
    required SummaryRepository summaryRepository,
  }) : _transactionRepository = transactionRepository,
       _summaryRepository = summaryRepository;

  /// Generate monthly summaries for all transactions
  Future<List<MonthlyTransactionSummary>> generateMonthlySummaries() async {
    try {
      // Get all transactions
      final transactions = await _transactionRepository.getAllTransactions();
      if (transactions.isEmpty) {
        return [];
      }

      // Group transactions by year and month
      final Map<String, List<Transaction>> transactionsByMonth = {};
      
      for (final transaction in transactions) {
        final date = transaction.date;
        final key = '${date.year}-${date.month}';
        
        if (!transactionsByMonth.containsKey(key)) {
          transactionsByMonth[key] = [];
        }
        
        transactionsByMonth[key]!.add(transaction);
      }
      
      // Generate summaries for each month
      final List<MonthlyTransactionSummary> summaries = [];
      
      transactionsByMonth.forEach((key, monthTransactions) {
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        final summary = MonthlyTransactionSummary.fromTransactions(
          monthTransactions, 
          year, 
          month
        );
        
        summaries.add(summary);
      });
      
      // Sort summaries by date (newest first)
      summaries.sort((a, b) {
        if (a.year != b.year) {
          return b.year.compareTo(a.year);
        }
        return b.month.compareTo(a.month);
      });
      
      // Save the generated summaries
      await _saveSummaries(summaries);
      
      return summaries;
    } catch (e) {
      debugPrint('Error generating monthly summaries: $e');
      rethrow;
    }
  }
  
  /// Save generated summaries to storage
  Future<void> _saveSummaries(List<MonthlyTransactionSummary> summaries) async {
    try {
      for (final summary in summaries) {
        await _summaryRepository.saveSummary(summary);
      }
    } catch (e) {
      debugPrint('Error saving monthly summaries: $e');
      rethrow;
    }
  }
  
  /// Get all monthly summaries
  Future<List<MonthlyTransactionSummary>> getAllSummaries() async {
    try {
      return await _summaryRepository.getAllSummaries();
    } catch (e) {
      debugPrint('Error getting monthly summaries: $e');
      rethrow;
    }
  }
  
  /// Get summary for a specific month
  Future<MonthlyTransactionSummary?> getSummaryForMonth(int year, int month) async {
    try {
      return await _summaryRepository.getSummaryForMonth(year, month);
    } catch (e) {
      debugPrint('Error getting summary for month: $e');
      rethrow;
    }
  }
  
  /// Regenerate monthly summary for a specific month after transaction changes
  Future<MonthlyTransactionSummary> regenerateSummaryForMonth(int year, int month) async {
    try {
      final transactions = await _transactionRepository.getTransactionsForMonth(year, month);
      final summary = MonthlyTransactionSummary.fromTransactions(transactions, year, month);
      await _summaryRepository.saveSummary(summary);
      return summary;
    } catch (e) {
      debugPrint('Error regenerating summary for month: $e');
      rethrow;
    }
  }
} 