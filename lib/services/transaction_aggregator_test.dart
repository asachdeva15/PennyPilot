import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'transaction_aggregator_service.dart';

/// This is a simple demonstration file showing how to use the transaction aggregator
/// This is not meant to be imported - it's just a usage example
void exampleUsage() {
  final transactions = [
    Transaction(
      id: '1',
      date: DateTime(2023, 1, 15),
      description: 'Salary',
      amount: 3000.0,
      bankName: 'MyBank',
    ),
    Transaction(
      id: '2',
      date: DateTime(2023, 1, 20),
      description: 'Grocery',
      amount: -150.0,
      bankName: 'MyBank',
    ),
    Transaction(
      id: '3',
      date: DateTime(2023, 2, 5),
      description: 'Rent',
      amount: -1200.0,
      bankName: 'MyBank',
    ),
    Transaction(
      id: '4',
      date: DateTime(2023, 2, 15),
      description: 'Salary',
      amount: 3000.0,
      bankName: 'MyBank',
    ),
  ];

  // Create the service
  final service = TransactionAggregatorService();
  
  // Group transactions by month
  final groupedTransactions = service.groupTransactionsByMonth(transactions);
  
  // Access transactions for January 2023
  final januaryKey = '2023-01';
  final januaryTransactions = groupedTransactions[januaryKey] ?? [];
  debugPrint('January transactions: ${januaryTransactions.length}'); // Should be 2
  
  // Get sorted month keys
  final sortedMonths = service.getSortedMonthKeys(groupedTransactions);
  debugPrint('Months in order: $sortedMonths'); // Should be ["2023-02", "2023-01"]
  
  // Get transactions for February 2023 using alternate method
  final februaryTransactions = service.getTransactionsForMonth(transactions, 2023, 2);
  debugPrint('February transactions: ${februaryTransactions.length}'); // Should be 2
} 