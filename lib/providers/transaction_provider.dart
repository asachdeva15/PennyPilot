import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/file_service.dart';

/// Provides access to transactions
class TransactionProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  final FileService _fileService = FileService();
  bool _isLoading = false;
  
  TransactionProvider() {
    loadTransactions();
  }
  
  bool get isLoading => _isLoading;
  List<Transaction> get transactions => _transactions;
  
  /// Loads all transactions from storage
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final loadedTransactions = await _fileService.loadAllTransactions();
      _transactions.clear();
      _transactions.addAll(loadedTransactions);
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _fileService.saveTransaction(transaction);
      _transactions.add(transaction);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }
  
  /// Updates an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _fileService.saveTransaction(transaction);
      
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index >= 0) {
        _transactions[index] = transaction;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
  }
  
  /// Gets transactions for a specific month
  List<Transaction> getTransactionsForMonth(int year, int month) {
    return _transactions.where((transaction) {
      final date = transaction.date;
      return date.year == year && date.month == month;
    }).toList();
  }
  
  /// Provides asynchronous access to transactions 
  Future<List<Transaction>> getTransactions() async {
    if (_transactions.isEmpty) {
      await loadTransactions();
    }
    return _transactions;
  }
} 