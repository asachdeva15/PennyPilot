import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/transaction_summary_service.dart';

class TransactionRepository implements ITransactionRepository {
  static const String _keyPrefix = 'transactions_';
  
  /// Retrieves all transactions stored in the repository
  @override
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      final List<Transaction> transactions = [];
      for (final key in keys) {
        final json = prefs.getString(key);
        if (json != null) {
          try {
            final Map<String, dynamic> map = jsonDecode(json);
            final transaction = Transaction.fromJson(map);
            transactions.add(transaction);
          } catch (e) {
            print('Error parsing transaction data: $e');
          }
        }
      }
      
      // Sort by date, newest first
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      print('Error retrieving transactions: $e');
      return [];
    }
  }

  /// Saves a transaction to the repository
  Future<bool> saveTransaction(Transaction transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(transaction.id);
      final json = jsonEncode(transaction.toJson());
      return await prefs.setString(key, json);
    } catch (e) {
      print('Error saving transaction: $e');
      return false;
    }
  }

  /// Saves multiple transactions at once
  Future<bool> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final transaction in transactions) {
        final key = _getKey(transaction.id);
        final json = jsonEncode(transaction.toJson());
        await prefs.setString(key, json);
      }
      
      return true;
    } catch (e) {
      print('Error saving transactions: $e');
      return false;
    }
  }

  /// Deletes a transaction from the repository
  Future<bool> deleteTransaction(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(id);
      return await prefs.remove(key);
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  /// Deletes all transactions from the repository
  Future<bool> deleteAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      return true;
    } catch (e) {
      print('Error deleting all transactions: $e');
      return false;
    }
  }

  /// Gets transactions for a specific month
  @override
  Future<List<Transaction>> getTransactionsForMonth(int year, int month) async {
    final allTransactions = await getAllTransactions();
    
    return allTransactions.where((transaction) {
      final date = transaction.date;
      return date.year == year && date.month == month;
    }).toList();
  }

  /// Helper method to generate a key for a transaction
  String _getKey(String id) {
    return '$_keyPrefix$id';
  }
} 