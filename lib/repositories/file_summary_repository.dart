import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/monthly_summary.dart';
import '../models/monthly_detailed_summary.dart';
import '../models/yearly_summary.dart';
import '../models/comprehensive_yearly_data.dart';
import '../services/file_service.dart';

/// Repository for storing and retrieving monthly and yearly financial summaries
/// using file-based storage instead of SharedPreferences
class FileSummaryRepository {
  final FileService _fileService;

  FileSummaryRepository({required FileService fileService})
      : _fileService = fileService;

  // --- Monthly Summary Methods ---

  /// Saves a monthly transaction summary
  Future<void> saveMonthlySummary(MonthlyTransactionSummary summary) async {
    try {
      final file = await _getMonthlySummaryFile(summary.year, summary.month);
      final jsonString = jsonEncode(summary.toJson());
      await file.writeAsString(jsonString);
      debugPrint('Monthly summary saved for ${summary.year}-${summary.month}');
      
      // Update the yearly summary after saving a monthly summary
      await _updateYearlySummary(summary.year);
    } catch (e) {
      debugPrint('Error saving monthly summary: $e');
      rethrow;
    }
  }

  /// Saves a detailed monthly summary with transactions
  Future<void> saveMonthlyDetailedSummary(MonthlyDetailedSummary detailedSummary) async {
    try {
      final file = await _getMonthlyDetailedSummaryFile(detailedSummary.year, detailedSummary.month);
      final jsonString = jsonEncode(detailedSummary.toJson());
      await file.writeAsString(jsonString);
      debugPrint('Detailed monthly summary saved for ${detailedSummary.year}-${detailedSummary.month}');
      
      // Save the summary version too for quick access
      await saveMonthlySummary(detailedSummary.toSummary());
    } catch (e) {
      debugPrint('Error saving detailed monthly summary: $e');
      rethrow;
    }
  }

  /// Gets a monthly summary for a specific year and month
  Future<MonthlyTransactionSummary?> getMonthlySummary(int year, int month) async {
    try {
      final file = await _getMonthlySummaryFile(year, month);
      if (!await file.exists()) {
        debugPrint('No monthly summary file exists for $year-$month');
        return null;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return MonthlyTransactionSummary.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading monthly summary: $e');
      return null;
    }
  }

  /// Gets a detailed monthly summary with transactions for a specific year and month
  Future<MonthlyDetailedSummary?> getMonthlyDetailedSummary(int year, int month) async {
    try {
      final file = await _getMonthlyDetailedSummaryFile(year, month);
      if (!await file.exists()) {
        debugPrint('No detailed monthly summary file exists for $year-$month');
        return null;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return MonthlyDetailedSummary.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading detailed monthly summary: $e');
      return null;
    }
  }

  /// Gets all monthly summaries
  Future<List<MonthlyTransactionSummary>> getAllMonthlySummaries() async {
    try {
      final summaryDir = await _getSummaryDirectory();
      if (!await summaryDir.exists()) {
        return [];
      }

      final List<MonthlyTransactionSummary> summaries = [];
      final entities = await summaryDir.list().toList();

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('_summary.json')) {
          try {
            final jsonString = await entity.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            summaries.add(MonthlyTransactionSummary.fromJson(jsonMap));
          } catch (e) {
            debugPrint('Error parsing summary file ${entity.path}: $e');
          }
        }
      }

      // Sort by date (newest first)
      summaries.sort((a, b) {
        final yearComparison = b.year.compareTo(a.year);
        if (yearComparison != 0) return yearComparison;
        return b.month.compareTo(a.month);
      });

      return summaries;
    } catch (e) {
      debugPrint('Error getting all monthly summaries: $e');
      return [];
    }
  }

  /// Gets monthly summaries for a specific year
  Future<List<MonthlyTransactionSummary>> getMonthlySummariesForYear(int year) async {
    final allSummaries = await getAllMonthlySummaries();
    return allSummaries.where((summary) => summary.year == year).toList();
  }

  /// Deletes a monthly summary
  Future<void> deleteMonthlySummary(int year, int month) async {
    try {
      final summaryFile = await _getMonthlySummaryFile(year, month);
      if (await summaryFile.exists()) {
        await summaryFile.delete();
      }

      final detailedFile = await _getMonthlyDetailedSummaryFile(year, month);
      if (await detailedFile.exists()) {
        await detailedFile.delete();
      }

      // Update the yearly summary after deleting a monthly summary
      await _updateYearlySummary(year);
    } catch (e) {
      debugPrint('Error deleting monthly summary: $e');
      rethrow;
    }
  }

  // --- Yearly Summary Methods ---

  /// Gets a yearly summary
  Future<YearlySummary?> getYearlySummary(int year) async {
    try {
      final file = await _getYearlySummaryFile(year);
      if (!await file.exists()) {
        debugPrint('No yearly summary file exists for $year');
        return null;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return YearlySummary.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading yearly summary: $e');
      return null;
    }
  }

  /// Saves a yearly summary
  Future<void> saveYearlySummary(YearlySummary summary) async {
    try {
      final file = await _getYearlySummaryFile(summary.year);
      final jsonString = jsonEncode(summary.toJson());
      await file.writeAsString(jsonString);
      debugPrint('Yearly summary saved for ${summary.year}');
    } catch (e) {
      debugPrint('Error saving yearly summary: $e');
      rethrow;
    }
  }

  /// Gets all yearly summaries
  Future<List<YearlySummary>> getAllYearlySummaries() async {
    try {
      final summaryDir = await _getSummaryDirectory();
      if (!await summaryDir.exists()) {
        return [];
      }

      final List<YearlySummary> summaries = [];
      final entities = await summaryDir.list().toList();

      for (final entity in entities) {
        if (entity is File && entity.path.contains('yearly_summary_')) {
          try {
            final jsonString = await entity.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            summaries.add(YearlySummary.fromJson(jsonMap));
          } catch (e) {
            debugPrint('Error parsing yearly summary file ${entity.path}: $e');
          }
        }
      }

      // Sort by year (newest first)
      summaries.sort((a, b) => b.year.compareTo(a.year));

      return summaries;
    } catch (e) {
      debugPrint('Error getting all yearly summaries: $e');
      return [];
    }
  }

  /// Updates the yearly summary by aggregating all monthly summaries for that year
  Future<void> _updateYearlySummary(int year) async {
    try {
      final monthlySummaries = await getMonthlySummariesForYear(year);
      if (monthlySummaries.isEmpty) {
        debugPrint('No monthly summaries found for year $year');
        return;
      }

      final yearlySummary = YearlySummary.fromMonthlySummaries(monthlySummaries);
      await saveYearlySummary(yearlySummary);
    } catch (e) {
      debugPrint('Error updating yearly summary: $e');
    }
  }

  /// Gets a comprehensive yearly data file
  Future<ComprehensiveYearlyData?> getComprehensiveYearlyData(int year) async {
    try {
      final file = await _getComprehensiveYearlyDataFile(year);
      if (!await file.exists()) {
        debugPrint('No comprehensive yearly data file exists for $year');
        return null;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return ComprehensiveYearlyData.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading comprehensive yearly data: $e');
      return null;
    }
  }

  /// Saves a comprehensive yearly data file
  Future<void> saveComprehensiveYearlyData(ComprehensiveYearlyData data) async {
    try {
      final file = await _getComprehensiveYearlyDataFile(data.year);
      final jsonString = jsonEncode(data.toJson());
      await file.writeAsString(jsonString);
      debugPrint('Comprehensive yearly data saved for ${data.year}');
    } catch (e) {
      debugPrint('Error saving comprehensive yearly data: $e');
      rethrow;
    }
  }

  // --- Helper Methods ---

  Future<Directory> _getSummaryDirectory() async {
    final baseDir = await _fileService.getDataDirectory();
    final summaryDir = Directory('${baseDir.path}/summaries');
    
    if (!await summaryDir.exists()) {
      await summaryDir.create(recursive: true);
    }
    
    return summaryDir;
  }

  Future<File> _getMonthlySummaryFile(int year, int month) async {
    final summaryDir = await _getSummaryDirectory();
    final monthStr = month.toString().padLeft(2, '0');
    return File('${summaryDir.path}/monthly_summary_${year}_$monthStr.json');
  }

  Future<File> _getMonthlyDetailedSummaryFile(int year, int month) async {
    final summaryDir = await _getSummaryDirectory();
    final monthStr = month.toString().padLeft(2, '0');
    return File('${summaryDir.path}/monthly_detailed_${year}_$monthStr.json');
  }

  Future<File> _getYearlySummaryFile(int year) async {
    final summaryDir = await _getSummaryDirectory();
    return File('${summaryDir.path}/yearly_summary_$year.json');
  }

  Future<File> _getComprehensiveYearlyDataFile(int year) async {
    final summaryDir = await _getSummaryDirectory();
    return File('${summaryDir.path}/${year}_complete.json');
  }
} 