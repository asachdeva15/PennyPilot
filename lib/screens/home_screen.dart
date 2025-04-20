import 'dart:convert'; // For utf8 decoding
import 'dart:io';    // For File operations
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart'; // Import the csv package
import 'mapping_screen.dart'; // Import the new mapping screen
import 'transaction_screen.dart'; // Import the transaction screen
import '../widgets/csv_preview_dialog.dart'; // Import the dialog
import '../services/file_service.dart';
import '../models/transaction.dart'; // Import transaction model
import '../models/bank_mapping.dart'; // Import bank mapping model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedBank;
  List<String> _banks = [];
  String? _filePath;
  bool _isLoading = false;
  bool _banksLoading = true; // State for loading banks initially

  // Instance of FileService
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request permissions on startup
    _loadBanks(); // Load banks when the screen initializes
  }

  // Request all required permissions upfront
  Future<void> _requestPermissions() async {
    try {
      // Request storage permissions
      await Permission.storage.request();
      
      // Request media permissions for Android 13+
      await Permission.photos.request();
      await Permission.audio.request();
      await Permission.videos.request();
      
      // Try create a test file directly
      try {
        if (Platform.isAndroid) {
          // Try writing to the app cache directory directly
          final cacheDir = Directory('/data/data/com.example.pennypilot/cache');
          if (!await cacheDir.exists()) {
            await cacheDir.create(recursive: true);
          }
          
          final testFile = File('${cacheDir.path}/permission_test.txt');
          await testFile.writeAsString('testing write permissions');
          await testFile.delete();
          print('Successfully created test file in app cache');
        } else {
          // Only try path_provider on non-Android platforms to avoid channel errors
          final appDir = await getApplicationDocumentsDirectory();
          final testDir = Directory('${appDir.path}/test_write');
          if (!await testDir.exists()) {
            await testDir.create(recursive: true);
          }
          await testDir.delete(recursive: true);
          print('Successfully created test directory in app documents');
        }
      } catch (e) {
        print('Error testing write permissions: $e');
        // Don't throw, just log the error
      }
      
    } catch (e) {
      print('Error requesting permissions: $e');
      // Don't throw, just log the error
    }
  }

  // --- Function to load saved bank names ---
  Future<void> _loadBanks() async {
    if (!mounted) return;
    setState(() {
      _banksLoading = true; // Indicate loading
    });
    try {
       // First ensure storage is initialized
       await _fileService.initializeStorage();
       
       // Then load bank names
       List<String> savedNames = await _fileService.listSavedBankNames();
       
       // Debug output of unsorted names
       print('Unsorted bank names: $savedNames');
       
       // Include "Other" with the bank names
       List<String> allBanks = ["Other", ...savedNames];
       
       // Sort all bank names alphabetically
       allBanks.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
       
       // Debug output of sorted names
       print('Sorted bank names: $allBanks');
       
       if (mounted) {
          setState(() {
             _banks = allBanks;
             
             // Set default selection to first bank in alphabetical order
             if (_selectedBank == null || !_banks.contains(_selectedBank)) {
               _selectedBank = _banks.isNotEmpty ? _banks[0] : null;
             }
             
             _banksLoading = false;
          });
       }
    } catch (e) {
       print("Error loading banks: $e");
       if (mounted) {
          setState(() {
             _banksLoading = false; // Stop loading even on error
          });
          // Show error message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load saved banks: ${e.toString()}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _loadBanks,
              ),
            ),
          );
       }
    }
  }
  // ---------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight / 5; // Top 1/5 of screen (changed from 1/4)
    
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFE68A00),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'LOGO.png',
                    width: 100,
                    height: 89,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PennyPilot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 0, // Zero height app bar to let the custom header show
        backgroundColor: const Color(0xFFE68A00),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Branded header with logo
          Container(
            height: headerHeight,
            width: double.infinity,
            color: const Color(0xFFE68A00), // #e68a00 color
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Image.asset(
                    'LOGO.png',
                    width: 150,
                    height: 110,
                  ),
                ],
              ),
            ),
          ),
          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '1. Select Bank:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Show loading indicator or dropdown
                  _banksLoading
                    ? const Center(child: CircularProgressIndicator())
                    : IgnorePointer(
                        ignoring: _isLoading, // Still ignore during file processing
                        child: DropdownButton<String>(
                          value: _selectedBank,
                          isExpanded: true,
                          items: _banks.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBank = newValue;
                            });
                          },
                        ),
                      ),
                  const SizedBox(height: 24),
                  const Text(
                    '2. Upload Bank CSV:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? Container( // Show loading indicator
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.upload_file), // Show icon otherwise
                      label: Text(_isLoading ? 'Processing...' : 'Select CSV File'),
                      onPressed: _isLoading ? null : _pickFile, // Disable button when loading
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filePath != null && !_isLoading) // Hide path when loading/no file
                    Text('Selected file: ${_filePath!.split('/').last}') // Show only filename
                  else if (!_isLoading)
                    const Text('No file selected yet.'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      // Debug button in a floating action button
      floatingActionButton: FloatingActionButton(
        mini: true,
        child: const Icon(Icons.bug_report),
        onPressed: _showDebugDialog,
      ),
    );
  }

  Future<bool> _requestPermission() async {
    PermissionStatus photosStatus = await Permission.photos.request();
    PermissionStatus videosStatus = await Permission.videos.request();
    PermissionStatus audioStatus = await Permission.audio.request();
    PermissionStatus storageStatus = await Permission.storage.request();

    if (photosStatus.isGranted || storageStatus.isGranted) {
      print('Storage permission granted.');
      return true;
    } else {
      print('Storage permission denied.');
      if (mounted) { // Check mounted before using context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to select files.')),
        );
      }
      return false;
    }
  }

  Future<void> _pickFile() async {
    bool hasPermission = await _requestPermission();
    if (!hasPermission || !mounted) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null && mounted) {
        setState(() {
          _filePath = result.files.single.path!; // Store the full path
          _isLoading = true; // Start loading indicator
        });

        // --- Add file processing logic here ---
        await _processSelectedFile(_filePath!);
        // -------------------------------------

      } else {
        print('User canceled file picking or widget unmounted.');
        if (mounted) {
          setState(() {
            _filePath = null;
          });
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        setState(() {
          _filePath = null;
          _isLoading = false; // Stop loading on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    } finally {
       // Ensure loading indicator stops eventually,
       // even if _processSelectedFile throws an error not caught below.
       // Specific error handling is inside _processSelectedFile now.
       // setState(() { _isLoading = false; }); // Moved inside _processSelectedFile or its catch block
    }
  }

  // --- New method to process the file ---
  Future<void> _processSelectedFile(String path) async {
    List<List<dynamic>> correctlyParsedRows = []; // To hold the final result
    bool navigatedAway = false;

    try {
      final file = File(path);
      final String csvString = await file.readAsString(encoding: latin1);

      // --- Minimal Initial Parse (Just for Row Count/Preview) ---
      // This helps the dialog know how many rows exist.
      // Columns might be wrong here if delimiter isn't comma.
      final List<List<dynamic>> previewRows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(csvString);
      print('[HomeScreen _processSelectedFile] Initial parse for preview - rows length: ${previewRows.length}');
      // -----------------------------------------------------------

      if (previewRows.isEmpty) {
        throw Exception("CSV file is empty.");
      }

      if (_selectedBank == 'Other' || _selectedBank == null) {
        print('[HomeScreen _processSelectedFile] Bank is "Other". Showing preview dialog.');
        navigatedAway = true;

        if (mounted) {
          // Show the preview dialog
          final selectedIndex = await showDialog<int?>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return CsvPreviewDialog(csvData: previewRows); // Use preview data
            },
          );

          if (selectedIndex != null && mounted) {
            print('[HomeScreen _processSelectedFile] Dialog returned header index: $selectedIndex');

            // --- Detect Delimiter on Selected Header Row ---
            final List<String> lines = LineSplitter.split(csvString).toList();
            if (selectedIndex >= lines.length) {
                 throw Exception("Selected header index out of bounds (lines).");
            }
            final String headerLine = lines[selectedIndex];
            final String detectedDelimiter = _detectDelimiter(headerLine);
            print('[HomeScreen _processSelectedFile] Detected delimiter: "$detectedDelimiter"');
            // ---------------------------------------------

            // --- Perform the FINAL PARSE with correct settings ---
            correctlyParsedRows = CsvToListConverter(
              shouldParseNumbers: false,
              eol: '\n', // Ensure row splitting is correct
              fieldDelimiter: detectedDelimiter, // Use detected column delimiter
            ).convert(csvString);
            print('[HomeScreen _processSelectedFile] FINAL parse - rows length: ${correctlyParsedRows.length}');

            if (selectedIndex < correctlyParsedRows.length) {
               print('[HomeScreen _processSelectedFile] FINAL parsed header row content: ${correctlyParsedRows[selectedIndex]}');
            } else {
               print('[HomeScreen _processSelectedFile] Error: selectedIndex out of bounds after FINAL parse.');
               throw Exception("Header index out of bounds after final parse.");
            }
            // --------------------------------------------------

            // Navigate with the DEFINITIVELY parsed data AND delimiter
            final result = await Navigator.push( // Capture result
              context,
              MaterialPageRoute(
                builder: (context) => MappingScreen(
                  csvData: correctlyParsedRows,
                  selectedHeaderRowIndex: selectedIndex,
                  detectedDelimiter: detectedDelimiter, // *** Pass delimiter ***
                ),
              ),
            );
            // *** Check result to refresh banks ***
            if (result == true && mounted) {
               print("Mapping saved, reloading banks...");
               _loadBanks(); // Function to refresh bank list
            }
            // Always clear file path after attempt
            setState(() { _filePath = null; });
          } else {
            print('[HomeScreen _processSelectedFile] Dialog cancelled or returned null.');
            setState(() { _filePath = null; });
          }
        }
      } else {
        // Known bank - process with saved mapping
        print('Bank "$_selectedBank" selected. Processing with known mapping.');
        
        // Debug - show mapping file location and contents
        try {
          // Add null check for _selectedBank
          if (_selectedBank != null) {
            final mapping = await _fileService.loadBankMapping(_selectedBank!);
            if (mapping != null) {
              print('DEBUG: Loaded mapping for $_selectedBank');
              print('DEBUG: Mapping: ${mapping.toJson()}');
              
              // Get the actual file path
              final file = await _fileService.getBankMappingFile(_selectedBank!);
              print('DEBUG: Mapping file path: ${file.path}');
              
              // --- Parse CSV with the saved mapping information ---
              final String detectedDelimiter = mapping.delimiter ?? ',';
              
              // Parse the CSV with correct delimiter
              correctlyParsedRows = CsvToListConverter(
                shouldParseNumbers: false,
                eol: '\n',
                fieldDelimiter: detectedDelimiter,
              ).convert(csvString);
              
              // Get header row
              final headerRow = correctlyParsedRows[mapping.headerRowIndex];
              
              // Create a map of column names to indices
              Map<String, int> columnMap = {};
              for (int i = 0; i < headerRow.length; i++) {
                columnMap[headerRow[i].toString()] = i;
              }
              
              // Extract transactions based on the mapping
              List<Transaction> transactions = [];
              
              // Process each data row (skip header)
              for (int i = mapping.headerRowIndex + 1; i < correctlyParsedRows.length; i++) {
                final dataRow = correctlyParsedRows[i];
                
                // Skip rows that don't have enough columns
                if (dataRow.length < headerRow.length) continue;
                
                // Create a map of column names to values for this row
                Map<String, dynamic> rowData = {};
                for (String columnName in columnMap.keys) {
                  final index = columnMap[columnName];
                  if (index != null && index < dataRow.length) {
                    rowData[columnName] = dataRow[index];
                  }
                }
                
                // Map the columns according to the bank mapping
                Map<String, dynamic> transactionData = {};
                
                // Map date column
                if (mapping.dateColumn != null && rowData.containsKey(mapping.dateColumn)) {
                  transactionData['date'] = rowData[mapping.dateColumn];
                }
                
                // Map description column
                if (mapping.descriptionColumn != null && rowData.containsKey(mapping.descriptionColumn)) {
                  transactionData['description'] = rowData[mapping.descriptionColumn];
                }
                
                // Map amount columns based on mapping type
                if (mapping.amountMappingType == AmountMappingType.single) {
                  // Single amount column
                  if (mapping.amountColumn != null && rowData.containsKey(mapping.amountColumn)) {
                    transactionData['amount'] = rowData[mapping.amountColumn];
                  }
                } else {
                  // Separate debit/credit columns
                  if (mapping.debitColumn != null && rowData.containsKey(mapping.debitColumn)) {
                    transactionData['debit'] = rowData[mapping.debitColumn];
                  }
                  if (mapping.creditColumn != null && rowData.containsKey(mapping.creditColumn)) {
                    transactionData['credit'] = rowData[mapping.creditColumn];
                  }
                }
                
                // Create transaction
                try {
                  final transaction = Transaction.fromCsvRow(
                    transactionData, 
                    _selectedBank!,
                    dateFormatType: mapping.dateFormatType ?? DateFormatType.iso // Provide a default value
                  );
                  transactions.add(transaction);
                } catch (e) {
                  print('Error creating transaction from row: $e');
                  // Skip this row and continue
                }
              }
              
              print('Parsed ${transactions.length} transactions from CSV');
              
              // Navigate to transaction screen
              navigatedAway = true;
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionScreen(
                      transactions: transactions,
                      bankName: _selectedBank!,
                    ),
                  ),
                );
                
                // Clear file path after returning
                setState(() { _filePath = null; });
              }
            } else {
              print('DEBUG: No mapping found for $_selectedBank!');
              _showError("No mapping found for selected bank. Please recreate the mapping.");
            }
          } else {
            print('DEBUG: Selected bank is null!');
            _showError("No bank selected");
          }
        } catch (e) {
          print('DEBUG: Error loading mapping for $_selectedBank: $e');
          _showError("Error loading bank mapping: $e");
        }
      }

    } catch (e) {
      print('Error processing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing file: $e')),
        );
        setState(() { _isLoading = false; }); // Stop loading on error
      }
    } finally {
      // Stop loading indicator logic remains largely the same
      if (mounted && !navigatedAway) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted && navigatedAway) {
          setState(() {
             _isLoading = false;
          });
      }
    }
  }

  // --- CORRECT IMPLEMENTATION for _detectDelimiter ---
  String _detectDelimiter(String headerLine) {
    // Count occurrences of common delimiters in the header line
    int commaCount = ','.allMatches(headerLine).length;
    int semicolonCount = ';'.allMatches(headerLine).length;
    // int tabCount = '\t'.allMatches(headerLine).length; // Can add later if needed

    print('[HomeScreen _detectDelimiter] Comma count: $commaCount, Semicolon count: $semicolonCount');

    // Prioritize semicolon if it's present and appears at least as often as comma
    if (semicolonCount > 0 && semicolonCount >= commaCount) {
      print('[HomeScreen _detectDelimiter] Returning Semicolon');
      return ';';
    }

    // Add check for tab if needed:
    // if (tabCount > 0 && tabCount >= commaCount && tabCount >= semicolonCount) {
    //    print('[HomeScreen _detectDelimiter] Returning Tab');
    //    return '\t';
    // }

    // Otherwise, default to comma
    print('[HomeScreen _detectDelimiter] Returning Comma (default)');
    return ',';
  }
  // *****************************************************

  // Show debug dialog with mapping file contents
  Future<void> _showDebugDialog() async {
    // Get all bank mappings
    final bankNames = await _fileService.listSavedBankNames();
    
    if (bankNames.isEmpty) {
      _showMessage('No bank mappings found.');
      return;
    }
    
    // Build a map of bank names to their file contents
    Map<String, String?> mappingContents = {};
    for (final bankName in bankNames) {
      mappingContents[bankName] = await _fileService.getBankMappingContents(bankName);
    }
    
    // Show the dialog with contents
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bank Mappings Debug'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mapping Files:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...bankNames.map((name) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mappingContents[name] ?? 'Error loading content',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final results = await _fileService.exportBankMappingsToDownloads();
                    Navigator.of(context).pop();
                    _showExportResults(results);
                  } catch (e) {
                    _showMessage('Error exporting files: $e');
                  }
                },
                child: const Text('Export to Downloads'),
              ),
            ],
          );
        },
      );
    }
  }
  
  // Show export results dialog
  void _showExportResults(Map<String, String> results) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Export Results'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: results.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('${entry.key}: ${entry.value}'),
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }
  
  // Show a simple message dialog
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() { 
      _isLoading = false;
      _filePath = null;
    });
  }
} 