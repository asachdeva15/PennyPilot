import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monthly_summary.dart';

class SummaryRepository {
  static const String _keyPrefix = 'monthly_summary_';
  
  /// Saves a monthly transaction summary to local storage
  Future<void> saveSummary(MonthlyTransactionSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(summary.year, summary.month);
    final json = jsonEncode(summary.toJson());
    await prefs.setString(key, json);
  }
  
  /// Retrieves a monthly summary for the specified year and month
  Future<MonthlyTransactionSummary?> getSummary(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(year, month);
    
    final json = prefs.getString(key);
    if (json == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> summaryMap = jsonDecode(json);
      return MonthlyTransactionSummary.fromJson(summaryMap);
    } catch (e) {
      print('Error parsing summary: $e');
      return null;
    }
  }
  
  /// Gets all stored monthly summaries
  Future<List<MonthlyTransactionSummary>> getAllSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final summaryKeys = allKeys.where((key) => key.startsWith(_keyPrefix));
    
    final summaries = <MonthlyTransactionSummary>[];
    
    for (final key in summaryKeys) {
      final json = prefs.getString(key);
      if (json != null) {
        try {
          final Map<String, dynamic> summaryMap = jsonDecode(json);
          final summary = MonthlyTransactionSummary.fromJson(summaryMap);
          summaries.add(summary);
        } catch (e) {
          print('Error parsing summary for key $key: $e');
        }
      }
    }
    
    // Sort by year and month (newest first)
    summaries.sort((a, b) {
      final yearComparison = b.year.compareTo(a.year);
      if (yearComparison != 0) {
        return yearComparison;
      }
      return b.month.compareTo(a.month);
    });
    
    return summaries;
  }
  
  /// Deletes a monthly summary for the specified year and month
  Future<void> deleteSummary(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(year, month);
    await prefs.remove(key);
  }
  
  /// Deletes all stored summaries
  Future<void> deleteAllSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final summaryKeys = allKeys.where((key) => key.startsWith(_keyPrefix));
    
    for (final key in summaryKeys) {
      await prefs.remove(key);
    }
  }
  
  /// Generates a key for storing a summary in SharedPreferences
  String _getKey(int year, int month) {
    return '${_keyPrefix}${year}_${month.toString().padLeft(2, '0')}';
  }
} 