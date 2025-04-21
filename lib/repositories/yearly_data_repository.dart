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
    try {
      // Always re-initialize
      _initialized = false;
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
    
    if (transactions.isEmpty) {
      print('No transactions to save');
      return true;
    }
    
    bool allSuccessful = true;
    
    for (final transaction in transactions) {
      final success = await saveTransaction(transaction);
      if (!success) {
        allSuccessful = false;
      }
    }
    
    return allSuccessful;
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
  
  /// Update an existing transaction
  Future<bool> updateTransaction(Transaction updatedTransaction) async {
    await _ensureInitialized();
    
    try {
      print('DEBUGGING: Updating transaction - ID: ${updatedTransaction.id}');
      print('DEBUGGING: New category: ${updatedTransaction.category}, subcategory: ${updatedTransaction.subcategory}');
      
      // Get the month data where the transaction belongs
      final year = updatedTransaction.date.year;
      final month = updatedTransaction.date.month;
      
      // Get the current yearly data
      final yearlyData = await getYearlyData(year);
      
      // Check if the month exists
      if (!yearlyData.months.containsKey(month)) {
        print('Month $month not found in year $year');
        return false;
      }
      
      // Get the month data
      final monthData = yearlyData.months[month]!;
      
      // Find the transaction to update
      final transactionIndex = monthData.transactions.indexWhere(
        (t) => t.id == updatedTransaction.id
      );
      
      if (transactionIndex == -1) {
        print('Transaction not found: ${updatedTransaction.id}');
        return false;
      }
      
      print('DEBUGGING: Found transaction at index $transactionIndex');
      print('DEBUGGING: Old transaction category: ${monthData.transactions[transactionIndex].category}, subcategory: ${monthData.transactions[transactionIndex].subcategory}');
      
      // Create a new list with the updated transaction
      final updatedTransactions = List<Transaction>.from(monthData.transactions);
      updatedTransactions[transactionIndex] = updatedTransaction;
      
      // Create updated month data
      final updatedMonthData = monthData.copyWith(
        transactions: updatedTransactions,
      );
      
      // Update the month in yearly data
      final success = await _fileService.updateMonth(
        year, 
        month, 
        updatedMonthData,
      );
      
      print('DEBUGGING: Update result: $success');
      
      return success;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }
  
  /// Delete a transaction
  Future<bool> deleteTransaction(Transaction transaction) async {
    await _ensureInitialized();
    
    try {
      // Get the month data where the transaction belongs
      final year = transaction.date.year;
      final month = transaction.date.month;
      
      // Get the current yearly data
      final yearlyData = await getYearlyData(year);
      
      // Check if the month exists
      if (!yearlyData.months.containsKey(month)) {
        print('Month $month not found in year $year');
        return false;
      }
      
      // Get the month data
      final monthData = yearlyData.months[month]!;
      
      // Find the transaction to delete
      final transactionIndex = monthData.transactions.indexWhere(
        (t) => t.id == transaction.id
      );
      
      if (transactionIndex == -1) {
        print('Transaction not found: ${transaction.id}');
        return false;
      }
      
      // Create a new list without the deleted transaction
      final updatedTransactions = List<Transaction>.from(monthData.transactions);
      updatedTransactions.removeAt(transactionIndex);
      
      // Create updated month data
      final updatedMonthData = monthData.copyWith(
        transactions: updatedTransactions,
      );
      
      // Update the month in yearly data
      final success = await _fileService.updateMonth(
        year, 
        month, 
        updatedMonthData,
      );
      
      if (success) {
        print('Transaction deleted successfully: ${transaction.id}');
      }
      
      return success;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }
  
  // Private helper to ensure the repository is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
} 