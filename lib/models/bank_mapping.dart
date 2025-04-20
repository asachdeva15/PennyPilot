import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../models/transaction.dart'; // Import for DateFormatType

// This tells the build runner to generate the serialization code
part 'bank_mapping.g.dart';

// Using the DateFormatType from transaction.dart
// enum DateFormatType {
//   iso,        // ISO format: 2023-12-31
//   mmddyyyy,   // US format: 12/31/2023
//   ddmmyyyy,   // European format: 31/12/2023
//   yyyymmdd,   // Sortable format: 2023-12-31
// }

enum AmountMappingType {
  single,     // One column for amount (positive/negative)
  separate,   // Separate columns for debit/credit
}

@JsonSerializable()
class BankMapping {
  final String bankName;
  final int headerRowIndex;
  
  // Column mappings
  final String? dateColumn;
  final String? descriptionColumn;
  final String? amountColumn;
  final String? debitColumn;
  final String? creditColumn;
  final String? otherColumn;
  
  // Format information
  final String? delimiter;
  final DateFormatType? dateFormatType;
  final AmountMappingType amountMappingType;
  
  // Internal checksum for file integrity validation
  final String? _checksum;
  
  BankMapping({
    required this.bankName,
    required this.headerRowIndex,
    this.dateColumn,
    this.descriptionColumn,
    this.amountColumn,
    this.debitColumn,
    this.creditColumn,
    this.otherColumn,
    this.delimiter,
    this.dateFormatType,
    this.amountMappingType = AmountMappingType.single,
    String? checksum,
  }) : _checksum = checksum;

  // Connect the generated functions
  factory BankMapping.fromJson(Map<String, dynamic> json) {
    return BankMapping(
      bankName: json['bankName'] as String,
      headerRowIndex: json['headerRowIndex'] as int,
      dateColumn: json['dateColumn'] as String?,
      descriptionColumn: json['descriptionColumn'] as String?,
      amountColumn: json['amountColumn'] as String?,
      debitColumn: json['debitColumn'] as String?,
      creditColumn: json['creditColumn'] as String?,
      otherColumn: json['otherColumn'] as String?,
      delimiter: json['delimiter'] as String?,
      dateFormatType: json['dateFormatType'] != null 
          ? DateFormatType.values[json['dateFormatType'] as int]
          : null,
      amountMappingType: json['amountMappingType'] != null
          ? AmountMappingType.values[json['amountMappingType'] as int]
          : AmountMappingType.single,
      checksum: json['_checksum'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'headerRowIndex': headerRowIndex,
      'dateColumn': dateColumn,
      'descriptionColumn': descriptionColumn,
      'amountColumn': amountColumn,
      'debitColumn': debitColumn,
      'creditColumn': creditColumn,
      'otherColumn': otherColumn,
      'delimiter': delimiter,
      'dateFormatType': dateFormatType?.index,
      'amountMappingType': amountMappingType.index,
      if (_checksum != null) '_checksum': _checksum,
    };
  }
  
  // Helper method to get date format pattern for parsing
  String getDateFormatPattern() {
    if (dateFormatType == null) {
      return 'YYYY-MM-DD'; // Default ISO format
    }
    
    switch (dateFormatType) {
      case DateFormatType.ddmmyyyy:
        return 'DD/MM/YYYY';
      case DateFormatType.mmddyyyy:
        return 'MM/DD/YYYY';
      case DateFormatType.yyyymmdd:
        return 'YYYY-MM-DD';
      case DateFormatType.iso:
      default:
        return 'YYYY-MM-DD';
    }
  }
} 