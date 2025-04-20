import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Service for ensuring file operations maintain data integrity
class FileIntegrityService {
  // Singleton instance
  static final FileIntegrityService _instance = FileIntegrityService._internal();
  factory FileIntegrityService() => _instance;
  FileIntegrityService._internal();
  
  /// Creates a backup of a file before modifying it
  Future<bool> backupFile(File file, {String? suffix}) async {
    try {
      if (!await file.exists()) {
        // No need to backup if file doesn't exist
        return true;
      }
      
      final backupPath = '${file.path}.${suffix ?? 'backup'}';
      final backupFile = File(backupPath);
      
      // Copy file contents to backup
      await file.copy(backupPath);
      
      return await backupFile.exists();
    } catch (e) {
      debugPrint('Error creating backup of ${file.path}: $e');
      return false;
    }
  }
  
  /// Restores a file from backup
  Future<bool> restoreFromBackup(File file, {String? suffix}) async {
    try {
      final backupPath = '${file.path}.${suffix ?? 'backup'}';
      final backupFile = File(backupPath);
      
      if (!await backupFile.exists()) {
        debugPrint('No backup file exists at $backupPath');
        return false;
      }
      
      // Copy backup contents to original file
      await backupFile.copy(file.path);
      
      // Verify restoration
      return await file.exists();
    } catch (e) {
      debugPrint('Error restoring ${file.path} from backup: $e');
      return false;
    }
  }
  
  /// Calculate MD5 checksum of a file
  Future<String> calculateChecksum(File file) async {
    try {
      if (!await file.exists()) {
        return '';
      }
      
      final contents = await file.readAsBytes();
      final digest = md5.convert(contents);
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating checksum for ${file.path}: $e');
      return '';
    }
  }
  
  /// Add checksum to JSON data
  Map<String, dynamic> addChecksumToJson(Map<String, dynamic> json) {
    // Clone the map to avoid modifying the original
    final jsonWithChecksum = Map<String, dynamic>.from(json);
    
    // Remove any existing checksum to avoid including it in the calculation
    jsonWithChecksum.remove('_checksum');
    
    // Calculate checksum of the JSON string
    final jsonString = jsonEncode(jsonWithChecksum);
    final checksumBytes = utf8.encode(jsonString);
    final checksum = md5.convert(checksumBytes).toString();
    
    // Add checksum to the JSON data
    jsonWithChecksum['_checksum'] = checksum;
    
    return jsonWithChecksum;
  }
  
  /// Validate checksum in JSON data
  bool validateJsonChecksum(Map<String, dynamic> json) {
    if (!json.containsKey('_checksum')) {
      return false; // No checksum to validate
    }
    
    final expectedChecksum = json['_checksum'] as String;
    
    // Remove checksum for calculation
    final jsonForValidation = Map<String, dynamic>.from(json);
    jsonForValidation.remove('_checksum');
    
    // Calculate checksum
    final jsonString = jsonEncode(jsonForValidation);
    final checksumBytes = utf8.encode(jsonString);
    final actualChecksum = md5.convert(checksumBytes).toString();
    
    return expectedChecksum == actualChecksum;
  }
  
  /// Safely write data to a file with validation
  Future<bool> safeWriteJson(File file, Map<String, dynamic> json) async {
    try {
      // Create backup of existing file
      await backupFile(file);
      
      // Add checksum to data
      final jsonWithChecksum = addChecksumToJson(json);
      final jsonString = jsonEncode(jsonWithChecksum);
      
      // Write to a temporary file first
      final tempPath = '${file.path}.tmp';
      final tempFile = File(tempPath);
      await tempFile.writeAsString(jsonString);
      
      // Verify the temporary file
      final tempContents = await tempFile.readAsString();
      final tempJson = jsonDecode(tempContents) as Map<String, dynamic>;
      final isValid = validateJsonChecksum(tempJson);
      
      if (!isValid) {
        debugPrint('Validation failed for temporary file');
        await tempFile.delete();
        return false;
      }
      
      // Replace the original file with the temporary file
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
      
      return true;
    } catch (e) {
      debugPrint('Error safely writing to ${file.path}: $e');
      // Try to restore from backup if writing failed
      try {
        await restoreFromBackup(file);
      } catch (e) {
        debugPrint('Error restoring from backup: $e');
      }
      return false;
    }
  }
  
  /// Safely read and validate JSON from a file
  Future<Map<String, dynamic>?> safeReadJson(File file) async {
    try {
      if (!await file.exists()) {
        return null;
      }
      
      // Read file contents
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate checksum if available
      if (json.containsKey('_checksum')) {
        final isValid = validateJsonChecksum(json);
        if (!isValid) {
          debugPrint('Checksum validation failed for ${file.path}');
          
          // Try to restore from backup
          final restored = await restoreFromBackup(file);
          if (restored) {
            // Read from restored file
            final restoredContents = await file.readAsString();
            final restoredJson = jsonDecode(restoredContents) as Map<String, dynamic>;
            
            // Validate restored data
            if (restoredJson.containsKey('_checksum') && validateJsonChecksum(restoredJson)) {
              debugPrint('Successfully restored from backup');
              return restoredJson;
            } else {
              debugPrint('Restored file also failed validation');
              // Return original data with warning
              return json;
            }
          } else {
            debugPrint('Could not restore from backup, returning original data with warning');
            return json;
          }
        }
      }
      
      return json;
    } catch (e) {
      debugPrint('Error safely reading from ${file.path}: $e');
      
      // Try to restore from backup
      try {
        final restored = await restoreFromBackup(file);
        if (restored) {
          final restoredContents = await file.readAsString();
          return jsonDecode(restoredContents) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error restoring from backup: $e');
      }
      
      return null;
    }
  }
  
  /// Verify consistency between monthly and yearly data
  Map<String, dynamic> verifyDataConsistency(
    Map<String, dynamic> yearlyData,
    List<Map<String, dynamic>> monthlyData
  ) {
    final consistencyIssues = <String, dynamic>{};
    
    try {
      // Extract yearly summary
      if (!yearlyData.containsKey('summary') || !yearlyData.containsKey('months')) {
        consistencyIssues['missingKeys'] = 'Yearly data missing summary or months';
        return consistencyIssues;
      }
      
      final yearlySummary = yearlyData['summary'] as Map<String, dynamic>;
      final months = yearlyData['months'] as Map<String, dynamic>;
      
      // Aggregate values from monthly data
      double totalIncome = 0;
      double totalExpenses = 0;
      double totalSavings = 0;
      int transactionCount = 0;
      final categoryTotals = <String, double>{};
      
      // Process each month in yearly data
      months.forEach((monthKey, monthData) {
        final monthSummary = monthData['summary'] as Map<String, dynamic>;
        
        // Add to totals
        totalIncome += (monthSummary['totalIncome'] as num).toDouble();
        totalExpenses += (monthSummary['totalExpenses'] as num).toDouble();
        totalSavings += (monthSummary['totalSavings'] as num).toDouble();
        transactionCount += monthSummary['transactionCount'] as int;
        
        // Add to category totals
        final monthCategoryTotals = monthSummary['categoryTotals'] as Map<String, dynamic>;
        monthCategoryTotals.forEach((category, amount) {
          categoryTotals[category] = (categoryTotals[category] ?? 0.0) + (amount as num).toDouble();
        });
      });
      
      // Compare with yearly summary
      final issues = <String>[];
      
      if ((yearlySummary['totalIncome'] as num).toDouble() != totalIncome) {
        issues.add('Income total mismatch');
      }
      
      if ((yearlySummary['totalExpenses'] as num).toDouble() != totalExpenses) {
        issues.add('Expenses total mismatch');
      }
      
      if ((yearlySummary['totalSavings'] as num).toDouble() != totalSavings) {
        issues.add('Savings total mismatch');
      }
      
      if (yearlySummary['transactionCount'] as int != transactionCount) {
        issues.add('Transaction count mismatch');
      }
      
      // Add any issues to result
      if (issues.isNotEmpty) {
        consistencyIssues['summaryIssues'] = issues;
        consistencyIssues['recalculatedValues'] = {
          'totalIncome': totalIncome,
          'totalExpenses': totalExpenses,
          'totalSavings': totalSavings,
          'transactionCount': transactionCount,
        };
      }
      
      return consistencyIssues;
    } catch (e) {
      debugPrint('Error verifying data consistency: $e');
      consistencyIssues['error'] = e.toString();
      return consistencyIssues;
    }
  }
} 