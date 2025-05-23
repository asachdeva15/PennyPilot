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
  String? otherData;
  String? csvId;

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
    this.otherData,
    this.csvId,
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
      otherData: json['otherData'] as String?,
      csvId: json['csvId'] as String?,
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
      'otherData': otherData,
      'csvId': csvId,
    };
  }
    
  // Create a copy with modified fields
  Transaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    String? category,
    String? subcategory,
    String? matchedKeyword,
    String? bankName,
    String? notes,
    String? otherData,
    String? csvId,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      matchedKeyword: matchedKeyword ?? this.matchedKeyword,
      bankName: bankName ?? this.bankName,
      notes: notes ?? this.notes,
      otherData: otherData ?? this.otherData,
      csvId: csvId ?? this.csvId,
    );
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
      final amountStr = rowData['amount'].toString();
      amount = _parseAmount(amountStr);
    } else if (rowData.containsKey('debit') && rowData.containsKey('credit')) {
      // Handle separate debit/credit columns
      final debitStr = rowData['debit'].toString();
      final creditStr = rowData['credit'].toString();
      
      // For Deutsche Bank format, both might be filled with values
      if (debitStr.isNotEmpty && creditStr.isEmpty) {
        // Debit is negative - Check if it's already negative
        final parsedAmount = _parseAmount(debitStr);
        if (parsedAmount < 0) {
          // It's already negative, keep it as is
          amount = parsedAmount;
        } else {
          // It's positive, make it negative
          amount = -1 * parsedAmount;
        }
      } else if (creditStr.isNotEmpty && debitStr.isEmpty) {
        amount = _parseAmount(creditStr); // Credit is positive
      } else if (debitStr.isNotEmpty && creditStr.isNotEmpty) {
        // Some banks may have values in both columns
        // Usually one is empty/zero and the other has the value
        final debitAmount = _parseAmount(debitStr);
        final creditAmount = _parseAmount(creditStr);
        
        if (debitAmount != 0 && creditAmount == 0) {
          // Debit is negative - check if already negative
          if (debitAmount < 0) {
            amount = debitAmount; // Already negative
          } else {
            amount = -debitAmount; // Make it negative
          }
        } else if (creditAmount != 0 && debitAmount == 0) {
          amount = creditAmount; // Credit is positive
        } else {
          // If both have values, use the larger one with appropriate sign
          if (debitAmount.abs() > creditAmount.abs()) {
            // Use debit (negative) - check if already negative
            if (debitAmount < 0) {
              amount = debitAmount; // Already negative
            } else {
              amount = -debitAmount; // Make it negative
            }
          } else {
            amount = creditAmount;
          }
        }
      }
    }
    
    // Parse date
    DateTime date = DateTime.now();
    if (rowData.containsKey('date')) {
      final dateStr = rowData['date'].toString();
      date = _parseDate(dateStr, dateFormatType);
    }
    
    // Get description
    String description = rowData['description']?.toString() ?? 'No description';
    
    // Get other data if available
    String? otherData = rowData['otherData']?.toString();
    
    // Create transaction with default category
    return Transaction(
      id: uuid.v4(),
      date: date,
      description: description,
      amount: amount,
      bankName: bankName ?? 'Unknown Bank',
      category: 'unknown',
      subcategory: 'uncategorized',
      otherData: otherData,
      csvId: uuid.v4(),
    );
  }
  
  // Helper method to parse date from string based on format
  static DateTime _parseDate(String dateStr, DateFormatType formatType) {
    try {
      // Cleanup the date string
      final cleanDateStr = dateStr.trim();
      
      // Handle empty string
      if (cleanDateStr.isEmpty) {
        return DateTime.now();
      }
      
      // Try to parse based on the expected format
      switch (formatType) {
        case DateFormatType.iso:
          // Handle ISO format: YYYY-MM-DD
          try {
            return DateTime.parse(cleanDateStr);
          } catch (e) {
            return DateTime.now();
          }
          break;
          
        case DateFormatType.mmddyyyy:
          // Handle MM/DD/YYYY format
          final parts = cleanDateStr.split(RegExp(r'[\/\.-]'));
          if (parts.length == 3) {
            try {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
              return DateTime(year, month, day);
            } catch (e) {
              return DateTime.now();
            }
          }
          break;
          
        case DateFormatType.ddmmyyyy:
          // Handle DD/MM/YYYY or DD.MM.YYYY format
          final parts = cleanDateStr.split(RegExp(r'[\/\.-]'));
          if (parts.length == 3) {
            try {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
              return DateTime(year, month, day);
            } catch (e) {
              return DateTime.now();
            }
          }
          break;
          
        case DateFormatType.yyyymmdd:
          // Handle YYYY-MM-DD or YYYY/MM/DD format
          final parts = cleanDateStr.split(RegExp(r'[\/\.-]'));
          if (parts.length == 3) {
            try {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              return DateTime(year, month, day);
            } catch (e) {
              return DateTime.now();
            }
          }
          break;
      }
      
      // Fallback: Try generic date parsing approaches
      
      // Try DD.MM.YYYY (common in Deutsche Bank)
      final dotPattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})');
      if (dotPattern.hasMatch(cleanDateStr)) {
        final match = dotPattern.firstMatch(cleanDateStr);
        if (match != null) {
          try {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final yearStr = match.group(3)!;
            final year = yearStr.length == 2 ? 2000 + int.parse(yearStr) : int.parse(yearStr);
            return DateTime(year, month, day);
          } catch (e) {
            return DateTime.now();
          }
        }
      }
      
      // Last attempt: use DateTime.tryParse
      final result = DateTime.tryParse(cleanDateStr);
      if (result != null) {
        return result;
      }
      
      return DateTime.now(); // Default to current date on error
    } catch (e) {
      return DateTime.now(); // Default to current date on error
    }
  }
  
  // Helper method to parse amount string to double
  static double _parseAmount(String amountStr) {
    try {
      // Handle empty string
      if (amountStr.trim().isEmpty) {
        return 0.0;
      }
      
      // Special handling for different number formats
      String cleanStr = amountStr.trim();
      bool isNegative = cleanStr.startsWith('-');
      
      // Remove minus sign temporarily to simplify regex matching
      if (isNegative) {
        cleanStr = cleanStr.substring(1);
      }
      
      // Handle "123,45" (European format with comma as decimal)
      if (RegExp(r'^\d+,\d+$').hasMatch(cleanStr)) {
        cleanStr = cleanStr.replaceAll(',', '.');
      }
      
      // Handle "1.234,56" (European thousands with dot separator and comma decimal)
      if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(cleanStr)) {
        cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
      }
      
      // Handle "1,234.56" (US format with comma as thousands separator)
      if (RegExp(r'^\d{1,3}(,\d{3})+(.\d+)?$').hasMatch(cleanStr)) {
        cleanStr = cleanStr.replaceAll(',', '');
      }
      
      // Handle currency symbols and other non-numeric chars
      cleanStr = cleanStr.replaceAll(RegExp(r'[^\d.-]'), '');
      
      // Handle special case of German banks sometimes using minus sign at the end
      if (cleanStr.endsWith('-')) {
        isNegative = true;
        cleanStr = cleanStr.substring(0, cleanStr.length - 1);
      }
      
      // Handle negative number in parentheses like "(123.45)"
      if (cleanStr.startsWith('(') && cleanStr.endsWith(')')) {
        isNegative = true;
        cleanStr = cleanStr.substring(1, cleanStr.length - 1);
      }
      
      // Reapply negative sign if needed
      if (isNegative) {
        cleanStr = '-' + cleanStr;
      }
      
      final result = double.parse(cleanStr);
      return result;
    } catch (e) {
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