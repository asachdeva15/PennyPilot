import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/bank_mapping.dart';
import '../services/file_service.dart'; // Import FileService
import '../models/transaction.dart'; // Import for DateFormatType

class MappingScreen extends StatefulWidget {
  final List<List<dynamic>> csvData; // Full CSV data
  final int selectedHeaderRowIndex;  // 0-based index passed from dialog
  final String detectedDelimiter; // *** Add delimiter ***

  const MappingScreen({
    super.key,
    required this.csvData,
    required this.selectedHeaderRowIndex,
    required this.detectedDelimiter, // *** Add to constructor ***
  });

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();

  // State for the actual header values once a row is selected
  List<String> _actualHeaders = [];

  // State variables for column mapping
  String? _selectedDateColumn;
  AmountMappingType _amountMappingType = AmountMappingType.single; // Default
  String? _selectedAmountColumn;    // For single column type
  String? _selectedDebitColumn;     // For separate columns type
  String? _selectedCreditColumn;    // For separate columns type
  String? _selectedDescriptionColumn;
  
  // Date format detection and selection
  DateFormatType _detectedDateFormat = DateFormatType.mmddyyyy; // Default to US format
  DateFormatType _selectedDateFormat = DateFormatType.mmddyyyy; // Default to US format
  String? _dateFormatExample = ""; // Example formatted date from CSV

  // Standard column names
  static const String standardDate = 'Date';
  static const String standardAmount = 'Amount';
  static const String standardDescription = 'Description';
  // --- Add standard names for separate columns ---
  static const String standardDebit = 'Debit Amount';
  static const String standardCredit = 'Credit Amount';
  // ---------------------------------------------

  final FileService _fileService = FileService(); // Instance of the service

  @override
  void initState() {
    super.initState();
    // Initialize headers based on the passed index
    if (widget.selectedHeaderRowIndex < widget.csvData.length) {
       _actualHeaders = widget.csvData[widget.selectedHeaderRowIndex]
          .map((h) => h.toString().trim())
          .toList();
    } else {
       // Handle error case: Invalid index passed (shouldn't happen with dialog validation)
       print("Error: Invalid selectedHeaderRowIndex passed to MappingScreen");
       _actualHeaders = [];
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }
  
  // Attempt to detect date format from sample data when date column is selected
  void _detectDateFormat(String dateColumn) {
    // Skip if no date column selected
    if (dateColumn.isEmpty) return;
    
    // Find column index
    int columnIndex = _actualHeaders.indexOf(dateColumn);
    if (columnIndex < 0) return;
    
    // Get some sample date values (skip header row)
    List<String> dateSamples = [];
    for (int i = widget.selectedHeaderRowIndex + 1; i < widget.csvData.length && dateSamples.length < 5; i++) {
      if (widget.csvData[i].length > columnIndex) {
        String dateValue = widget.csvData[i][columnIndex].toString().trim();
        if (dateValue.isNotEmpty) {
          dateSamples.add(dateValue);
        }
      }
    }
    
    if (dateSamples.isEmpty) return;
    
    // Try to determine format based on patterns in sample dates
    _dateFormatExample = dateSamples.first;
    
    // Detect format by analyzing the pattern
    DateFormatType detectedFormat = _detectFormatFromSample(dateSamples);
    
    setState(() {
      _detectedDateFormat = detectedFormat;
      _selectedDateFormat = detectedFormat; // Set selected format to detected format
    });
    
    debugPrint('Detected date format: $_detectedDateFormat from samples: $dateSamples');
  }
  
  // Logic to detect date format from samples
  DateFormatType _detectFormatFromSample(List<String> samples) {
    // Analyze samples to determine format
    for (final sample in samples) {
      if (sample.contains('/')) {
        // US format (MM/DD/YYYY) or European format (DD/MM/YYYY)
        final parts = sample.split('/');
        if (parts.length == 3) {
          // Check if first part is likely a month (1-12) or day (1-31)
          try {
            final firstNum = int.parse(parts[0]);
            if (firstNum > 12 && firstNum <= 31) {
              // First number > 12, likely European format DD/MM/YYYY
              return DateFormatType.ddmmyyyy;
            } else {
              // First number <= 12, could be either format, default to US
              return DateFormatType.mmddyyyy;
            }
          } catch (e) {
            // Not a number, default to US format
          }
        }
      } else if (sample.contains('-')) {
        // ISO format (YYYY-MM-DD) or something else
        final parts = sample.split('-');
        if (parts.length == 3) {
          // Check if first part is a 4-digit year
          if (parts[0].length == 4) {
            return DateFormatType.yyyymmdd;
          }
        }
      }
    }
    
    // Default to US format if nothing detected
    return DateFormatType.mmddyyyy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map CSV Columns'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '1. Enter Bank Name:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., My Bank, Chase Credit Card',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a bank name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                '2. Map CSV columns to standard fields:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                 '(Using Row ${widget.selectedHeaderRowIndex + 1} as header)',
                 style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _buildMappingRow(
                standardLabel: standardDate,
                options: _actualHeaders, // Use initialized headers
                selectedValue: _selectedDateColumn,
                onChanged: (value) { 
                  setState(() { 
                    _selectedDateColumn = value; 
                    // Try to detect date format when date column is selected
                    if (value != null && value.isNotEmpty) {
                      _detectDateFormat(value);
                    }
                  }); 
                },
              ),
              
              // Date format selection section
              if (_selectedDateColumn != null && _selectedDateColumn!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Date Format:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (_dateFormatExample != null && _dateFormatExample!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Sample date from CSV: $_dateFormatExample',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                RadioListTile<DateFormatType>(
                  title: Text('MM/DD/YYYY (US Format)' + 
                      (_detectedDateFormat == DateFormatType.mmddyyyy ? ' - Detected' : '')),
                  value: DateFormatType.mmddyyyy,
                  groupValue: _selectedDateFormat,
                  onChanged: (DateFormatType? value) {
                    if (value != null) {
                      setState(() {
                        _selectedDateFormat = value;
                      });
                    }
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<DateFormatType>(
                  title: Text('DD/MM/YYYY (European Format)' + 
                      (_detectedDateFormat == DateFormatType.ddmmyyyy ? ' - Detected' : '')),
                  value: DateFormatType.ddmmyyyy,
                  groupValue: _selectedDateFormat,
                  onChanged: (DateFormatType? value) {
                    if (value != null) {
                      setState(() {
                        _selectedDateFormat = value;
                      });
                    }
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<DateFormatType>(
                  title: Text('YYYY-MM-DD (ISO Format)' + 
                      (_detectedDateFormat == DateFormatType.yyyymmdd ? ' - Detected' : '')),
                  value: DateFormatType.yyyymmdd,
                  groupValue: _selectedDateFormat,
                  onChanged: (DateFormatType? value) {
                    if (value != null) {
                      setState(() {
                        _selectedDateFormat = value;
                      });
                    }
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
              ],
              
              const SizedBox(height: 16),
              const Text('Amount Representation:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              RadioListTile<AmountMappingType>(
                 title: const Text('Single "Amount" Column'),
                 value: AmountMappingType.single,
                 groupValue: _amountMappingType,
                 onChanged: (AmountMappingType? value) {
                   setState(() {
                     _amountMappingType = value!;
                     // Reset other amount fields when changing type
                     _selectedDebitColumn = null;
                     _selectedCreditColumn = null;
                   });
                 },
                 dense: true, // Make it more compact
                 contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<AmountMappingType>(
                 title: const Text('Separate "Debit" and "Credit" Columns'),
                 value: AmountMappingType.separate,
                 groupValue: _amountMappingType,
                 onChanged: (AmountMappingType? value) {
                   setState(() {
                     _amountMappingType = value!;
                     // Reset other amount field when changing type
                     _selectedAmountColumn = null;
                   });
                 },
                 dense: true,
                 contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              if (_amountMappingType == AmountMappingType.single)
                _buildMappingRow(
                  standardLabel: standardAmount, // Use the conceptual "Amount" label
                  options: _actualHeaders,
                  selectedValue: _selectedAmountColumn,
                  onChanged: (value) { setState(() { _selectedAmountColumn = value; }); },
                   // Make validator specific if needed
                   isRequired: true, // Assuming amount is always required
                )
              else // AmountMappingType.separate
                Column(
                  children: [
                    _buildMappingRow(
                      standardLabel: standardDebit, // Specific label
                      options: _actualHeaders,
                      selectedValue: _selectedDebitColumn,
                      onChanged: (value) { setState(() { _selectedDebitColumn = value; }); },
                       isRequired: true, // Assuming debit is required
                    ),
                    _buildMappingRow(
                      standardLabel: standardCredit, // Specific label
                      options: _actualHeaders,
                      selectedValue: _selectedCreditColumn,
                      onChanged: (value) { setState(() { _selectedCreditColumn = value; }); },
                       isRequired: true, // Assuming credit is required
                    ),
                  ],
                ),
              _buildMappingRow(
                standardLabel: standardDescription,
                options: _actualHeaders,
                selectedValue: _selectedDescriptionColumn,
                onChanged: (value) { setState(() { _selectedDescriptionColumn = value; }); },
                 isRequired: true, // Assuming description is required
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveMappingAndProcess,
                  child: const Text('Save Mapping & Process Transactions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMappingRow({
    required String standardLabel,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    bool isRequired = true, // Add parameter to control validation
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text('$standardLabel:', style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: selectedValue,
              hint: const Text('Select CSV Column'),
              isExpanded: true,
              items: options.where((o) => o.isNotEmpty).map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
              validator: (value) {
                 // Only validate if the field is marked as required
                 if (isRequired && value == null) {
                   return 'Required';
                 }
                 return null;
              },
              decoration: const InputDecoration(
                 border: OutlineInputBorder(),
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveMappingAndProcess() async {
    if (_formKey.currentState!.validate()) {
      final bankName = _bankNameController.text.trim();

      // --- Create BankMapping Object ---
      final BankMapping newMapping = BankMapping(
        bankName: bankName,
        headerRowIndex: widget.selectedHeaderRowIndex,
        amountMappingType: _amountMappingType,
        dateColumn: _selectedDateColumn,
        descriptionColumn: _selectedDescriptionColumn,
        amountColumn: _amountMappingType == AmountMappingType.single ? _selectedAmountColumn : null,
        debitColumn: _amountMappingType == AmountMappingType.separate ? _selectedDebitColumn : null,
        creditColumn: _amountMappingType == AmountMappingType.separate ? _selectedCreditColumn : null,
        delimiter: widget.detectedDelimiter,
        dateFormatType: _selectedDateFormat, // Save the selected date format
      );
      // --------------------------------

      try {
          // --- Save the Mapping using FileService ---
          final success = await _fileService.saveBankMapping(newMapping);
          
          if (!success) {
            throw Exception('Failed to save bank mapping');
          }
          // ------------------------------------------

          debugPrint('Bank Name: $bankName');
          debugPrint('Selected Header Row Index (0-based): ${widget.selectedHeaderRowIndex}');
          debugPrint('Actual Headers: $_actualHeaders');
          debugPrint('Mapping Type: $_amountMappingType');
          debugPrint('Date Format: ${newMapping.getDateFormatPattern()}');
          debugPrint('Mapping Object: ${jsonEncode(newMapping.toJson())}'); // Print saved JSON

          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mapping saved successfully for $bankName')),
             );
             // Pop with the mapping object to indicate success and pass the mapping back
             Navigator.pop(context, newMapping);
          }

      } catch (e) {
          debugPrint("Error saving mapping: $e");
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving mapping: $e')),
             );
          }
      }

    } else {
      debugPrint('Form validation failed.');
    }
  }
} 