import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/yearly_data.dart';
import '../models/monthly_data.dart';
import 'file_service.dart';

/// Service for handling storage of yearly financial data as JSON files
class YearlyFileService {
  final FileService _fileService = FileService();
  
  // Directory paths
  Directory? _baseDirectory;
  
  // Current data in memory
  YearlyData? _currentYearData;
  MonthlyData? _currentMonthData;
  int? _currentYear;
  int? _currentMonth;
  
  // Initialize the service
  Future<bool> initialize() async {
    try {
      // Get the directory 
      _baseDirectory = await _fileService.getDataDirectory();
      
      // Load current year/month data
      await _loadCurrentPeriod();
      
      return true;
    } catch (e) {
      print('Failed to initialize YearlyFileService: $e');
      return false;
    }
  }
  
  // Load current year and month data
  Future<void> _loadCurrentPeriod() async {
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    
    // Try to load current month data first (optimization)
    await _loadCurrentMonthData();
    
    // Then load current year data
    await _loadCurrentYearData();
  }
  
  // Get the file path for a specific year's data
  String _getYearlyFilePath(int year) {
    return '${_baseDirectory!.path}/$year.json';
  }
  
  // Get the file path for the current month's data
  String get _currentMonthFilePath {
    return '${_baseDirectory!.path}/current_month.json';
  }
  
  // Load the current year's data
  Future<YearlyData> _loadCurrentYearData() async {
    if (_currentYear == null) {
      throw Exception('Current year not initialized');
    }
    
    if (_currentYearData != null) {
      return _currentYearData!;
    }
    
    try {
      final filePath = _getYearlyFilePath(_currentYear!);
      final file = File(filePath);
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        _currentYearData = YearlyData.fromJson(json);
      } else {
        // Create new yearly data structure
        _currentYearData = YearlyData.empty(_currentYear!);
        await _saveCurrentYearData();
      }
      
      return _currentYearData!;
    } catch (e) {
      print('Error loading yearly data: $e');
      // Create new data on error
      _currentYearData = YearlyData.empty(_currentYear!);
      await _saveCurrentYearData();
      return _currentYearData!;
    }
  }
  
  // Load current month data
  Future<MonthlyData> _loadCurrentMonthData() async {
    if (_currentYear == null || _currentMonth == null) {
      throw Exception('Current year/month not initialized');
    }
    
    if (_currentMonthData != null) {
      return _currentMonthData!;
    }
    
    try {
      final filePath = _currentMonthFilePath;
      final file = File(filePath);
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        
        // Verify the current month data is for the correct month
        final monthData = MonthlyData.fromJson(json);
        if (monthData.year == _currentYear && monthData.month == _currentMonth) {
          _currentMonthData = monthData;
        } else {
          // This is data from a previous month, archive it and create new
          await _archiveMonthData(monthData);
          _currentMonthData = MonthlyData.empty(_currentYear!, _currentMonth!);
          await _saveCurrentMonthData();
        }
      } else {
        // Create new monthly data
        _currentMonthData = MonthlyData.empty(_currentYear!, _currentMonth!);
        await _saveCurrentMonthData();
      }
      
      return _currentMonthData!;
    } catch (e) {
      print('Error loading current month data: $e');
      // Create new data on error
      _currentMonthData = MonthlyData.empty(_currentYear!, _currentMonth!);
      await _saveCurrentMonthData();
      return _currentMonthData!;
    }
  }
  
  // Save the current year's data
  Future<bool> _saveCurrentYearData() async {
    if (_currentYearData == null) {
      throw Exception('No yearly data to save');
    }
    
    try {
      final filePath = _getYearlyFilePath(_currentYearData!.year);
      final file = File(filePath);
      
      // Convert to JSON string
      final jsonString = jsonEncode(_currentYearData!.toJson());
      
      // Write to file
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      print('Error saving yearly data: $e');
      return false;
    }
  }
  
  // Save current month data
  Future<bool> _saveCurrentMonthData() async {
    if (_currentMonthData == null) {
      throw Exception('No current month data to save');
    }
    
    try {
      final filePath = _currentMonthFilePath;
      final file = File(filePath);
      
      // Convert to JSON
      final jsonString = jsonEncode(_currentMonthData!.toJson());
      
      // Write to file
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      print('Error saving current month data: $e');
      return false;
    }
  }
  
  // Archive month data to yearly file
  Future<bool> _archiveMonthData(MonthlyData monthData) async {
    try {
      // Load the appropriate year file
      final year = monthData.year;
      final filePath = _getYearlyFilePath(year);
      final file = File(filePath);
      
      YearlyData yearData;
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        yearData = YearlyData.fromJson(json);
      } else {
        yearData = YearlyData.empty(year);
      }
      
      // Update the month in the yearly data
      yearData = yearData.updateMonth(monthData.month, monthData);
      
      // Save the updated yearly data
      final jsonString = jsonEncode(yearData.toJson());
      await file.writeAsString(jsonString, flush: true);
      
      return true;
    } catch (e) {
      print('Error archiving month data: $e');
      return false;
    }
  }
  
  // Add a transaction to the current month
  Future<bool> addTransaction(Transaction transaction) async {
    await _loadCurrentMonthData();
    
    final transactionDate = transaction.date;
    
    // Check if transaction belongs in current month
    if (transactionDate.year == _currentYear && transactionDate.month == _currentMonth) {
      // Add to current month
      _currentMonthData = _currentMonthData!.addTransaction(transaction);
      return await _saveCurrentMonthData();
    } else {
      // Transaction belongs to a different month
      // We need to load that month's data, add the transaction, and save
      final year = transactionDate.year;
      final month = transactionDate.month;
      
      try {
        // Load the appropriate yearly data
        final yearFilePath = _getYearlyFilePath(year);
        final yearFile = File(yearFilePath);
        
        YearlyData yearData;
        
        if (await yearFile.exists()) {
          final contents = await yearFile.readAsString();
          final json = jsonDecode(contents) as Map<String, dynamic>;
          yearData = YearlyData.fromJson(json);
        } else {
          yearData = YearlyData.empty(year);
        }
        
        // Get the month data
        MonthlyData monthData = yearData.getMonth(month);
        
        // Add transaction
        monthData = monthData.addTransaction(transaction);
        
        // Update year data
        yearData = yearData.updateMonth(month, monthData);
        
        // Save year data
        final jsonString = jsonEncode(yearData.toJson());
        await yearFile.writeAsString(jsonString, flush: true);
        
        return true;
      } catch (e) {
        print('Error adding transaction to different month: $e');
        return false;
      }
    }
  }
  
  // Get transactions for a specific month
  Future<List<Transaction>> getTransactionsForMonth(int year, int month) async {
    // If it's the current month, return from current month data
    if (year == _currentYear && month == _currentMonth && _currentMonthData != null) {
      return _currentMonthData!.transactions;
    }
    
    try {
      // Try to get from yearly file
      final yearFilePath = _getYearlyFilePath(year);
      final yearFile = File(yearFilePath);
      
      if (await yearFile.exists()) {
        final contents = await yearFile.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        final yearData = YearlyData.fromJson(json);
        
        // Get the month data
        final monthData = yearData.months[month];
        if (monthData != null) {
          return monthData.transactions;
        }
      }
      
      // If we get here, no data was found
      return [];
    } catch (e) {
      print('Error getting transactions for month: $e');
      return [];
    }
  }
  
  // Get yearly data
  Future<YearlyData> getYearlyData(int year) async {
    if (year == _currentYear && _currentYearData != null) {
      // Make sure current month data is included
      if (_currentMonthData != null) {
        // Check if current month data needs to be merged into yearly data
        if (!_currentYearData!.months.containsKey(_currentMonth) || 
            _currentYearData!.months[_currentMonth]!.transactions.length != 
            _currentMonthData!.transactions.length) {
          // Merge current month data
          _currentYearData = _currentYearData!.updateMonth(_currentMonth!, _currentMonthData!);
        }
      }
      return _currentYearData!;
    }
    
    try {
      final filePath = _getYearlyFilePath(year);
      final file = File(filePath);
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return YearlyData.fromJson(json);
      } else {
        return YearlyData.empty(year);
      }
    } catch (e) {
      print('Error loading yearly data: $e');
      return YearlyData.empty(year);
    }
  }
  
  // Migrate transactions from SharedPreferences
  Future<bool> migrateFromSharedPreferences() async {
    try {
      // Get all transactions from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final transactionKeys = prefs.getKeys()
          .where((key) => key.startsWith('transactions_'))
          .toList();
      
      int migratedCount = 0;
      
      for (final key in transactionKeys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final transaction = Transaction.fromJson(json);
            
            // Add to the appropriate month/year
            await addTransaction(transaction);
            migratedCount++;
          } catch (e) {
            print('Error migrating transaction $key: $e');
          }
        }
      }
      
      print('Migrated $migratedCount transactions from SharedPreferences');
      
      // Force save of any pending changes
      if (_currentMonthData != null) {
        await _saveCurrentMonthData();
      }
      
      if (_currentYearData != null) {
        await _saveCurrentYearData();
      }
      
      return true;
    } catch (e) {
      print('Error during migration: $e');
      return false;
    }
  }
  
  // Helper methods for repair operations
  
  // Get the File object for a yearly data file
  Future<File> _getYearlyFile(int year) async {
    return File(_getYearlyFilePath(year));
  }
  
  // Get the File object for a monthly data file
  Future<File> _getMonthlyFile(int year, int month) async {
    final monthStr = month.toString().padLeft(2, '0');
    return File('${_baseDirectory!.path}/month_${year}_$monthStr.json');
  }
  
  // Read yearly data from file
  Future<YearlyData?> readYearlyData(int year) async {
    try {
      final file = await _getYearlyFile(year);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return YearlyData.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error reading yearly data: $e');
      return null;
    }
  }
  
  // Read monthly data from file
  Future<MonthlyData?> _readMonthlyData(int year, int month) async {
    try {
      final file = await _getMonthlyFile(year, month);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return MonthlyData.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error reading monthly data: $e');
      return null;
    }
  }
  
  // Write yearly data to file
  Future<bool> _writeYearlyData(YearlyData data) async {
    try {
      final file = await _getYearlyFile(data.year);
      final jsonString = jsonEncode(data.toJson());
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      print('Error writing yearly data: $e');
      return false;
    }
  }
  
  Future<bool> verifyYearlyData(int year) async {
    try {
      final yearlyFile = await _getYearlyFile(year);
      
      // If the yearly file doesn't exist, create empty yearly data
      if (!await yearlyFile.exists()) {
        final emptyYearlyData = YearlyData.empty(year);
        await _writeYearlyData(emptyYearlyData);
        return true;
      }
      
      final yearlyData = await readYearlyData(year);
      if (yearlyData == null) {
        return false;
      }
      
      // Verify each month in the yearly data
      final months = yearlyData.months.keys.toList();
      for (final monthStr in months) {
        final month = int.tryParse(monthStr.toString());
        if (month == null) continue;
        
        final monthlyFile = await _getMonthlyFile(year, month);
        if (!await monthlyFile.exists()) {
          return false; // Monthly file is missing
        }
      }
      
      return true;
    } catch (e) {
      print('Error verifying yearly data: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>> repairYearlyData(int year) async {
    try {
      final yearlyFile = await _getYearlyFile(year);
      
      // Create empty yearly data if it doesn't exist
      if (!await yearlyFile.exists()) {
        final emptyYearlyData = YearlyData.empty(year);
        await _writeYearlyData(emptyYearlyData);
        return {
          'success': true,
          'message': 'Created new yearly data file for $year',
          'created': true
        };
      }
      
      // Read existing yearly data
      final yearlyData = await readYearlyData(year);
      if (yearlyData == null) {
        return {
          'success': false,
          'message': 'Failed to read yearly data for $year'
        };
      }
      
      // Get all months that have data files
      final List<int> availableMonths = [];
      for (int month = 1; month <= 12; month++) {
        final monthlyFile = await _getMonthlyFile(year, month);
        if (await monthlyFile.exists()) {
          availableMonths.add(month);
        }
      }
      
      // Update yearly data with all available monthly data
      var updatedYearlyData = yearlyData;
      bool anyUpdates = false;
      
      for (final month in availableMonths) {
        final monthlyData = await _readMonthlyData(year, month);
        if (monthlyData != null) {
          updatedYearlyData = updatedYearlyData.updateMonth(month, monthlyData);
          anyUpdates = true;
        }
      }
      
      // Recalculate summary
      updatedYearlyData = updatedYearlyData.recalculateSummary(updatedYearlyData.months);
      
      // Save the updated yearly data
      await _writeYearlyData(updatedYearlyData);
      
      return {
        'success': true,
        'message': anyUpdates ? 'Successfully repaired yearly data for $year' : 'No repairs needed for $year',
        'updated': anyUpdates
      };
    } catch (e) {
      print('Error repairing yearly data: $e');
      return {
        'success': false,
        'message': 'Error repairing yearly data: $e'
      };
    }
  }
} 