import '../models/transaction.dart';
import '../models/yearly_data.dart';
import '../models/monthly_data.dart';
import '../services/yearly_file_service.dart';

/// Repository for managing yearly financial data
class YearlyDataRepository {
  final YearlyFileService _fileService = YearlyFileService();
  bool _initialized = false;
  
  /// Initialize the repository
  Future<bool> initialize() async {
    if (_initialized) return true;
    
    try {
      _initialized = await _fileService.initialize();
      return _initialized;
    } catch (e) {
      print('Failed to initialize YearlyDataRepository: $e');
      return false;
    }
  }
  
  /// Save a transaction
  Future<bool> saveTransaction(Transaction transaction) async {
    await _ensureInitialized();
    return await _fileService.addTransaction(transaction);
  }
  
  /// Save multiple transactions at once
  Future<bool> saveTransactions(List<Transaction> transactions) async {
    await _ensureInitialized();
    
    bool allSucceeded = true;
    for (final transaction in transactions) {
      final success = await _fileService.addTransaction(transaction);
      if (!success) {
        allSucceeded = false;
      }
    }
    
    return allSucceeded;
  }
  
  /// Get transactions for a specific month
  Future<List<Transaction>> getTransactionsForMonth(int year, int month) async {
    await _ensureInitialized();
    return await _fileService.getTransactionsForMonth(year, month);
  }
  
  /// Get yearly data
  Future<YearlyData> getYearlyData(int year) async {
    await _ensureInitialized();
    return await _fileService.getYearlyData(year);
  }
  
  /// Get yearly data for the current year
  Future<YearlyData> getCurrentYearData() async {
    final now = DateTime.now();
    return await getYearlyData(now.year);
  }
  
  /// Migrate data from old storage system to new
  Future<bool> migrateFromLegacyStorage() async {
    await _ensureInitialized();
    return await _fileService.migrateFromSharedPreferences();
  }
  
  // Private helper to ensure the repository is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _initialized = await initialize();
      if (!_initialized) {
        throw Exception('Failed to initialize repository');
      }
    }
  }
} 