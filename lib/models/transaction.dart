import 'package:uuid/uuid.dart';

// Not using freezed to fix compatibility issues
class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  String? category;
  String? subcategory;
  String? matchedKeyword;
  final String bankName;
  String? notes;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.category,
    this.subcategory,
    this.matchedKeyword,
    required this.bankName,
    this.notes,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      amount: json['amount'] as double,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      matchedKeyword: json['matchedKeyword'] as String?,
      bankName: json['bankName'] as String,
      notes: json['notes'] as String?,
    );
  }
    
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'matchedKeyword': matchedKeyword,
      'bankName': bankName,
      'notes': notes,
    };
  }
    
  // Helper factory to create from CSV row data
  factory Transaction.fromCsvRow(
    Map<String, dynamic> rowData, 
    String? bankName, {
    DateFormatType dateFormatType = DateFormatType.iso,
  }) {
    // Convert data from CSV to a Transaction
    final uuid = Uuid();
    
    // Parse amount
    double amount = 0.0;
    if (rowData.containsKey('amount')) {
      amount = _parseAmount(rowData['amount'].toString());
    } else if (rowData.containsKey('debit') && rowData.containsKey('credit')) {
      // Handle separate debit/credit columns
      final debitStr = rowData['debit'].toString();
      final creditStr = rowData['credit'].toString();
      
      if (debitStr.isNotEmpty) {
        amount = -1 * _parseAmount(debitStr); // Debit is negative
      } else if (creditStr.isNotEmpty) {
        amount = _parseAmount(creditStr); // Credit is positive
      }
    }
    
    // Parse date
    DateTime date = DateTime.now();
    if (rowData.containsKey('date')) {
      date = _parseDate(rowData['date'].toString(), dateFormatType);
    }
    
    // Create transaction
    return Transaction(
      id: uuid.v4(),
      date: date,
      description: rowData['description']?.toString() ?? 'No description',
      amount: amount,
      bankName: bankName ?? 'Unknown Bank',
    );
  }
  
  // Helper method to parse date from string based on format
  static DateTime _parseDate(String dateStr, DateFormatType formatType) {
    try {
      switch (formatType) {
        case DateFormatType.iso:
          return DateTime.parse(dateStr);
        case DateFormatType.mmddyyyy:
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[0]), // month
              int.parse(parts[1]), // day
            );
          }
          break;
        case DateFormatType.ddmmyyyy:
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month
              int.parse(parts[0]), // day
            );
          }
          break;
        case DateFormatType.yyyymmdd:
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]), // year
              int.parse(parts[1]), // month
              int.parse(parts[2]), // day
            );
          }
          break;
      }
      
      // Fallback: try basic parsing
      return DateTime.parse(dateStr);
    } catch (e) {
      print('Error parsing date "$dateStr": $e');
      return DateTime.now(); // Default to current date on error
    }
  }
  
  // Helper method to parse amount string to double
  static double _parseAmount(String amountStr) {
    try {
      // Remove currency symbols and commas
      final cleanStr = amountStr.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.parse(cleanStr);
    } catch (e) {
      print('Error parsing amount "$amountStr": $e');
      return 0.0; // Default to zero on error
    }
  }
}

enum DateFormatType {
  iso,        // ISO format: 2023-12-31
  mmddyyyy,   // US format: 12/31/2023
  ddmmyyyy,   // European format: 31/12/2023
  yyyymmdd,   // Sortable format: 2023-12-31
} 