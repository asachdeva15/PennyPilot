import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/file_service.dart';
import '../services/transaction_summary_service.dart';

class FileTransactionRepository implements ITransactionRepository {
  final FileService _fileService;
  
  FileTransactionRepository({required FileService fileService})
      : _fileService = fileService;

  /// Retrieves all transactions stored in the repository
  @override
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final transactionsDir = await _getTransactionsDirectory();
      if (!await transactionsDir.exists()) {
        debugPrint('Transactions directory does not exist');
        return [];
      }
      
      final List<Transaction> transactions = [];
      final entities = await transactionsDir.list().toList();
      
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final jsonString = await entity.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            transactions.add(Transaction.fromJson(jsonMap));
          } catch (e) {
            debugPrint('Error parsing transaction file ${entity.path}: $e');
          }
        }
      }
      
      // Sort by date, newest first
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      debugPrint('Error retrieving transactions: $e');
      return [];
    }
  }

  /// Saves a transaction to the repository
  Future<bool> saveTransaction(Transaction transaction) async {
    try {
      final file = await _getTransactionFile(transaction.id);
      final jsonString = jsonEncode(transaction.toJson());
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return false;
    }
  }

  /// Saves multiple transactions at once
  Future<bool> saveTransactions(List<Transaction> transactions) async {
    try {
      for (final transaction in transactions) {
        final file = await _getTransactionFile(transaction.id);
        final jsonString = jsonEncode(transaction.toJson());
        await file.writeAsString(jsonString);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving transactions: $e');
      return false;
    }
  }

  /// Deletes a transaction from the repository
  Future<bool> deleteTransaction(String id) async {
    try {
      final file = await _getTransactionFile(id);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  /// Deletes all transactions from the repository
  Future<bool> deleteAllTransactions() async {
    try {
      final dir = await _getTransactionsDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting all transactions: $e');
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

  // Helper methods for file paths
  
  Future<Directory> _getTransactionsDirectory() async {
    final baseDir = await _fileService.getDataDirectory();
    final transactionsDir = Directory('${baseDir.path}/transactions');
    
    if (!await transactionsDir.exists()) {
      await transactionsDir.create(recursive: true);
    }
    
    return transactionsDir;
  }
  
  Future<File> _getTransactionFile(String id) async {
    final dir = await _getTransactionsDirectory();
    return File('${dir.path}/transaction_$id.json');
  }
} 