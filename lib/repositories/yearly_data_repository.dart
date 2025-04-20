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
    
    // Get existing transactions for the month to check for duplicates
    final transactionYear = transaction.date.year;
    final transactionMonth = transaction.date.month;
    final existingTransactions = await _fileService.getTransactionsForMonth(transactionYear, transactionMonth);
    
    // Check for duplicates before saving
    for (final existingTransaction in existingTransactions) {
      // Check if it's a duplicate based on date, description, and amount
      if (existingTransaction.date.day == transaction.date.day &&
          existingTransaction.date.month == transaction.date.month &&
          existingTransaction.date.year == transaction.date.year &&
          existingTransaction.description == transaction.description &&
          existingTransaction.amount == transaction.amount) {
        // It's a duplicate, skip saving
        print('Skipping duplicate transaction: ${transaction.description} on ${transaction.date} for ${transaction.amount}');
        return true; // Return true as if it succeeded (we're skipping it intentionally)
      }
    }
    
    // Not a duplicate, proceed with saving
    return await _fileService.addTransaction(transaction);
  }
  
  /// Save multiple transactions at once
  Future<bool> saveTransactions(List<Transaction> transactions) async {
    await _ensureInitialized();
    
    // Get existing transactions for duplicate checking
    Map<int, List<Transaction>> existingTransactionsByMonth = {};
    
    bool allSucceeded = true;
    for (final transaction in transactions) {
      final transactionYear = transaction.date.year;
      final transactionMonth = transaction.date.month;
      
      // Load existing transactions for this month/year if not already loaded
      if (!existingTransactionsByMonth.containsKey(transactionMonth)) {
        existingTransactionsByMonth[transactionMonth] = 
            await _fileService.getTransactionsForMonth(transactionYear, transactionMonth);
      }
      
      // Check for duplicates
      bool isDuplicate = false;
      for (final existingTransaction in existingTransactionsByMonth[transactionMonth]!) {
        // Check if it's a duplicate based on date, description, and amount
        if (existingTransaction.date.day == transaction.date.day &&
            existingTransaction.date.month == transaction.date.month &&
            existingTransaction.date.year == transaction.date.year &&
            existingTransaction.description == transaction.description &&
            existingTransaction.amount == transaction.amount) {
          isDuplicate = true;
          print('Skipping duplicate transaction: ${transaction.description} on ${transaction.date} for ${transaction.amount}');
          break;
        }
      }
      
      // Only save if not a duplicate
      if (!isDuplicate) {
        final success = await _fileService.addTransaction(transaction);
        
        if (success) {
          // Add to our local cache of existing transactions to check against future imports
          existingTransactionsByMonth[transactionMonth]!.add(transaction);
        } else {
          allSucceeded = false;
        }
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
      await initialize();
    }
  }
} 