import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../models/monthly_summary.dart';
import '../models/monthly_detailed_summary.dart';
import '../models/transaction.dart';
import '../models/yearly_summary.dart';
import '../repositories/file_summary_repository.dart';
import '../models/comprehensive_yearly_data.dart';

// Abstract repository interface
abstract class ITransactionRepository {
  Future<List<Transaction>> getAllTransactions();
  Future<List<Transaction>> getTransactionsForMonth(int year, int month);
}

class TransactionSummaryService {
  final ITransactionRepository _transactionRepository;
  final FileSummaryRepository _summaryRepository;

  TransactionSummaryService({
    required ITransactionRepository transactionRepository,
    required FileSummaryRepository summaryRepository,
  })  : _transactionRepository = transactionRepository,
        _summaryRepository = summaryRepository;

  /// Generates a monthly summary for the specified year and month
  Future<MonthlyTransactionSummary> generateMonthlySummary(int year, int month) async {
    try {
      // Get all transactions for the specified month
      final allTransactions = await _transactionRepository.getAllTransactions();
      
      // Create a detailed summary with transactions
      final detailedSummary = MonthlyDetailedSummary.fromTransactions(
        allTransactions, 
        year, 
        month
      );
      
      // Save the detailed summary
      await _summaryRepository.saveMonthlyDetailedSummary(detailedSummary);
      
      // Return the summary-only version
      return detailedSummary.toSummary();
    } catch (e) {
      debugPrint('Error generating monthly summary: $e');
      rethrow;
    }
  }

  /// Gets a monthly summary for the specified year and month,
  /// generating it if it doesn't exist
  Future<MonthlyTransactionSummary> getMonthlySummary(int year, int month) async {
    try {
      // Try to retrieve an existing summary
      final existingSummary = await _summaryRepository.getMonthlySummary(year, month);
      
      // If summary exists, return it
      if (existingSummary != null) {
        return existingSummary;
      }
      
      // Otherwise, generate a new summary
      return await generateMonthlySummary(year, month);
    } catch (e) {
      debugPrint('Error getting monthly summary: $e');
      rethrow;
    }
  }

  /// Gets a detailed monthly summary with transactions for the specified year and month
  Future<MonthlyDetailedSummary> getMonthlyDetailedSummary(int year, int month) async {
    try {
      // Try to retrieve an existing detailed summary
      final existingDetailedSummary = await _summaryRepository.getMonthlyDetailedSummary(year, month);
      
      // If detailed summary exists, return it
      if (existingDetailedSummary != null) {
        return existingDetailedSummary;
      }
      
      // Otherwise, generate a new detailed summary
      final allTransactions = await _transactionRepository.getAllTransactions();
      final detailedSummary = MonthlyDetailedSummary.fromTransactions(
        allTransactions, 
        year, 
        month
      );
      
      // Save the detailed summary
      await _summaryRepository.saveMonthlyDetailedSummary(detailedSummary);
      
      return detailedSummary;
    } catch (e) {
      debugPrint('Error getting detailed monthly summary: $e');
      rethrow;
    }
  }

  /// Gets all available monthly summaries
  Future<List<MonthlyTransactionSummary>> getAllMonthlySummaries() async {
    try {
      return await _summaryRepository.getAllMonthlySummaries();
    } catch (e) {
      debugPrint('Error getting all monthly summaries: $e');
      rethrow;
    }
  }

  /// Deletes a specific monthly summary
  Future<void> deleteMonthlySummary(int year, int month) async {
    try {
      await _summaryRepository.deleteMonthlySummary(year, month);
    } catch (e) {
      debugPrint('Error deleting monthly summary: $e');
      rethrow;
    }
  }

  /// Regenerates all monthly summaries by finding all unique month/year combinations
  /// in the transaction history and generating summaries for each
  Future<List<MonthlyTransactionSummary>> regenerateAllSummaries() async {
    try {
      // Get all transactions
      final allTransactions = await _transactionRepository.getAllTransactions();
      
      // Find all unique year/month combinations
      final monthYearSet = <MapEntry<int, int>>{};
      for (final transaction in allTransactions) {
        monthYearSet.add(MapEntry(transaction.date.year, transaction.date.month));
      }
      
      // Sort them chronologically
      final monthYearList = monthYearSet.toList()
        ..sort((a, b) {
          final yearComparison = b.key.compareTo(a.key); // Newest first
          if (yearComparison != 0) return yearComparison;
          return b.value.compareTo(a.value); // Newest month first
        });
      
      // Generate summaries for each month/year
      final summaries = <MonthlyTransactionSummary>[];
      for (final yearMonth in monthYearList) {
        // Create and save detailed summary
        final detailedSummary = MonthlyDetailedSummary.fromTransactions(
          allTransactions,
          yearMonth.key,
          yearMonth.value
        );
        
        await _summaryRepository.saveMonthlyDetailedSummary(detailedSummary);
        summaries.add(detailedSummary.toSummary());
      }
      
      return summaries;
    } catch (e) {
      debugPrint('Error regenerating all summaries: $e');
      rethrow;
    }
  }

  /// Gets a yearly summary, generating it if it doesn't exist
  Future<YearlySummary> getYearlySummary(int year) async {
    try {
      // Try to retrieve an existing yearly summary
      final existingSummary = await _summaryRepository.getYearlySummary(year);
      
      // If it exists, return it
      if (existingSummary != null) {
        return existingSummary;
      }
      
      // Otherwise, get or generate all monthly summaries for this year
      final monthlySummaries = await _getMonthlySummariesForYear(year);
      
      // If there are no monthly summaries, generate them first
      if (monthlySummaries.isEmpty) {
        await regenerateAllSummaries();
        return await getYearlySummary(year); // Recursive call after regenerating
      }
      
      // Create and save yearly summary
      final yearlySummary = YearlySummary.fromMonthlySummaries(monthlySummaries);
      await _summaryRepository.saveYearlySummary(yearlySummary);
      
      return yearlySummary;
    } catch (e) {
      debugPrint('Error getting yearly summary: $e');
      rethrow;
    }
  }

  /// Gets all available yearly summaries
  Future<List<YearlySummary>> getAllYearlySummaries() async {
    try {
      return await _summaryRepository.getAllYearlySummaries();
    } catch (e) {
      debugPrint('Error getting all yearly summaries: $e');
      rethrow;
    }
  }

  /// Gets comprehensive data for a specific year including yearly summary,
  /// monthly summaries, and transactions grouped by month
  Future<ComprehensiveYearlyData> getComprehensiveYearlyData(int year) async {
    try {
      // Try to get cached comprehensive data first
      final cachedData = await _summaryRepository.getComprehensiveYearlyData(year);
      if (cachedData != null) {
        return cachedData;
      }

      // If not cached, we need to build it from scratch
      // Get yearly summary
      final yearlySummary = await getYearlySummary(year);
      
      // Get monthly summaries for this year
      final monthlySummaries = await _getMonthlySummariesForYear(year);
      
      // Get all transactions for this year
      final allTransactions = await _transactionRepository.getAllTransactions();
      
      // Generate comprehensive data
      final comprehensiveData = ComprehensiveYearlyData.generateFromTransactions(
        year,
        allTransactions,
        yearlySummary,
        monthlySummaries,
      );
      
      // Cache the comprehensive data
      await _summaryRepository.saveComprehensiveYearlyData(comprehensiveData);
      
      return comprehensiveData;
    } catch (e) {
      debugPrint('Error getting comprehensive yearly data: $e');
      rethrow;
    }
  }

  /// Generates and saves comprehensive data for a specific year, rebuilding from scratch
  /// Use this method when you want to force regeneration of the data
  Future<ComprehensiveYearlyData> generateComprehensiveYearlyData(int year) async {
    try {
      // Generate or regenerate the yearly summary
      await regenerateAllSummaries();
      final yearlySummary = await getYearlySummary(year);
      
      // Get monthly summaries for this year
      final monthlySummaries = await _getMonthlySummariesForYear(year);
      
      // Get all transactions for this year
      final allTransactions = await _transactionRepository.getAllTransactions();
      
      // Generate comprehensive data
      final comprehensiveData = ComprehensiveYearlyData.generateFromTransactions(
        year,
        allTransactions,
        yearlySummary,
        monthlySummaries,
      );
      
      // Cache the comprehensive data
      await _summaryRepository.saveComprehensiveYearlyData(comprehensiveData);
      
      return comprehensiveData;
    } catch (e) {
      debugPrint('Error generating comprehensive yearly data: $e');
      rethrow;
    }
  }

  /// Helper method to get monthly summaries for a year
  Future<List<MonthlyTransactionSummary>> _getMonthlySummariesForYear(int year) async {
    return await _summaryRepository.getMonthlySummariesForYear(year);
  }
} 