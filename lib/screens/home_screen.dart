import 'dart:convert'; // For utf8 decoding
import 'dart:io';    // For File operations
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart'; // Import the csv package
import 'mapping_screen.dart'; // Import the new mapping screen
import 'transaction_screen.dart'; // Import the transaction screen
import 'yearly_detail_screen.dart'; // Import the yearly detail screen
import 'transaction_history_screen.dart'; // Import the transaction history screen
import '../services/file_service.dart';
import '../models/transaction.dart'; // Import transaction model
import '../models/bank_mapping.dart'; // Import bank mapping model
import '../providers/yearly_data_provider.dart';
import '../repositories/yearly_data_repository.dart';
import '../screens/category_management_screen.dart';
import '../screens/category_mapping_screen.dart';
import '../models/yearly_data.dart';
import '../models/monthly_data.dart';
import 'data_upload_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  String? _errorMessage;
  BankMapping? _currentMapping; // Add this field for bank mapping
  YearlyData? _yearlyData;
  final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

  // Instance of FileService
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request permissions on startup
    _loadBanks(); // Load banks when the screen initializes
    
    // Check if current month data needs archiving
    _checkCurrentMonthData();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh banks whenever the dependencies change (e.g., returning from other screens)
    _loadBanks();
    // Always reload yearly data when returning to this screen
    _loadData();
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
       List<String> allBanks = ["Other"];
       
       // Add any saved names that aren't empty
       if (savedNames.isNotEmpty) {
         allBanks.addAll(savedNames.where((name) => name.isNotEmpty));
       }
       
       // Sort all bank names alphabetically
       allBanks.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
       
       // Debug output of sorted names
       print('Sorted bank names: $allBanks');
       
       if (mounted) {
          setState(() {
             _banks = allBanks;
             
             // If we already have a selection and it's still valid, keep it
             if (_selectedBank != null && _banks.contains(_selectedBank)) {
               // Keep current selection
             }
             // Otherwise, set default selection to first bank in alphabetical order
             else {
               _selectedBank = _banks.isNotEmpty ? _banks[0] : null;
             }
             
             _banksLoading = false;
          });
       }
    } catch (e) {
       print("Error loading banks: $e");
       if (mounted) {
          setState(() {
             // Even on error, ensure we have at least the "Other" option
             if (_banks.isEmpty) {
               _banks = ["Other"];
               _selectedBank = "Other";
             }
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
      drawer: _buildDrawer(),
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
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildYearlySummary(),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkDataIntegrity,
        backgroundColor: Colors.green,
        child: const Icon(Icons.check_circle),
        tooltip: 'Check Data Integrity',
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
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
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload Transactions'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const DataUploadScreen()),
              ).then((_) {
                // Refresh data when returning from upload screen
                _loadData();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Transaction History'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
              ).then((_) {
                // Refresh data when returning
                _loadData();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('Category Mappings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CategoryMappingScreen()),
              ).then((_) {
                // Refresh data when returning
                _loadData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySummary() {
    if (_yearlyData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No yearly data available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToYearlyDetailScreen(),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yearly Summary',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total Income', _yearlyData!.summary.totalIncome, Colors.green),
                  _buildSummaryRow('Total Expenses', _yearlyData!.summary.totalExpenses, Colors.red),
                  _buildSummaryRow('Total Savings', _yearlyData!.summary.totalSavings, Colors.blue),
                  _buildSummaryRow('Transactions', _yearlyData!.summary.transactionCount.toDouble(), Colors.grey),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Last Updated: ${_yearlyData!.summary.lastUpdated != null 
                      ? DateFormat('yyyy-MM-dd HH:mm').format(_yearlyData!.summary.lastUpdated!) 
                      : 'Not available'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Navigate to yearly detail screen
  void _navigateToYearlyDetailScreen() {
    if (_yearlyData == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YearlyDetailScreen(yearlyData: _yearlyData!),
      ),
    );
  }

  // Helper method to get a color for each category
  Color _getCategoryColor(String category) {
    // Map categories to specific colors
    final Map<String, Color> categoryColors = {
      'Fundamentals': Colors.blue,
      'Lifestyle': Colors.purple,
      'Income': Colors.green,
      'Uncategorized': Colors.grey,
    };
    
    // Return the mapped color or a default
    return categoryColors[category] ?? Colors.orange;
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            label == 'Transactions' ? value.toInt().toString() : currencyFormat.format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
        await _processSelectedFile(File(_filePath!));
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
    }
  }

  // --- New method to process the file ---
  Future<void> _processSelectedFile(File file) async {
    try {
      // Show progress indicator
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // If "Other" is selected, show CSV preview and mapping screen
      if (_selectedBank == "Other") {
        setState(() {
          _isLoading = false; // Stop loading indicator while in preview mode
        });
        
        await _showCsvPreviewAndMapping(file);
        return; // Return early as the flow will continue after mapping
      }
      
      // For known banks, try to load its mapping
      if (_selectedBank != null) {
        _currentMapping = await _fileService.loadBankMapping(_selectedBank!);
      }
      
      // Process the file with the loaded mapping
      print('Processing CSV file: ${file.path}');
      
      final List<Transaction> parsedTransactions = await _fileService.processCSVFile(
        file,
        _selectedBank,
        _currentMapping,
      );
      
      print('Parsed ${parsedTransactions.length} transactions from CSV');
      
      if (parsedTransactions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No valid transactions found in the CSV file.';
        });
        
        // Show error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No valid transactions found in the CSV file.')),
        );
        return;
      }
      
      // Save transactions using the new yearly data repository
      final yearlyRepo = YearlyDataRepository();
      await yearlyRepo.initialize();
      final bool saveSuccess = await yearlyRepo.saveTransactions(parsedTransactions);
      
      if (saveSuccess) {
        print('Successfully saved ${parsedTransactions.length} transactions to yearly JSON structure');
            } else {
        print('Warning: Some transactions may not have been saved to yearly JSON structure');
      }
      
      // Show transaction screen with results
      if (!mounted) return;
      
      Navigator.of(context).push(
              MaterialPageRoute(
          builder: (context) => TransactionScreen(
            transactions: parsedTransactions,
            bankName: _selectedBank ?? "Unknown", // Provide default value for non-nullable field
                ),
              ),
            );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error processing CSV file: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error processing file: $e';
      });
      
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing file: $e')),
      );
    }
  }

  // New method to handle CSV preview and mapping for "Other" bank
  Future<void> _showCsvPreviewAndMapping(File file) async {
    try {
      // Read the file
      final csvString = await file.readAsString(encoding: latin1);
      
      // Detect delimiter
      final String detectedDelimiter = _detectDelimiter(csvString);
      print('Detected delimiter: "$detectedDelimiter"');
      
      // Parse CSV with detected delimiter
      final parser = CsvToListConverter(
                shouldParseNumbers: false,
                eol: '\n',
                fieldDelimiter: detectedDelimiter,
      );
      final rows = parser.convert(csvString);
      
      if (rows.isEmpty) {
        _showMessage('CSV file is empty or invalid.');
        return;
      }
      
      // Show dialog to select header row and preview CSV
      final headerRowIndex = await _showHeaderSelectionDialog(rows);
      if (headerRowIndex == null) {
        // User cancelled
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('Selected header row index: $headerRowIndex');
      
      // Navigate to mapping screen
      if (!mounted) return;
      
      final result = await Navigator.of(context).push<BankMapping>(
        MaterialPageRoute(
          builder: (context) => MappingScreen(
            csvData: rows,
            selectedHeaderRowIndex: headerRowIndex,
            detectedDelimiter: detectedDelimiter,
          ),
        ),
      );
      
      // If user created a mapping, process the file with it
      if (result != null) {
        print('Received bank mapping: ${result.bankName}');
        
        setState(() {
          _isLoading = true; // Start loading again
        });
        
        // Refresh the bank list to include the new mapping
        await _loadBanks();
        
        // If the new mapping isn't in the dropdown selection yet, select it
        if (!_banks.contains(result.bankName)) {
          _banks.add(result.bankName);
          _banks.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        }
        
        // Select the new bank mapping
        setState(() {
          _selectedBank = result.bankName;
        });
        
        // Process the file with the new mapping
        final List<Transaction> parsedTransactions = await _fileService.processCSVFile(
          file,
          result.bankName,
          result,
        );
        
        // Continue with transaction processing
        if (parsedTransactions.isEmpty) {
          _showMessage('No valid transactions found in the CSV file.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Save transactions
        final yearlyRepo = YearlyDataRepository();
        await yearlyRepo.initialize();
        await yearlyRepo.saveTransactions(parsedTransactions);
        
        // Show transaction screen
              if (mounted) {
          Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TransactionScreen(
                transactions: parsedTransactions,
                bankName: result.bankName,
                    ),
                  ),
                );
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error in CSV preview: $e');
      _showMessage('Error previewing CSV: $e');
        setState(() {
          _isLoading = false;
        });
      }
  }
  
  // Dialog to select header row
  Future<int?> _showHeaderSelectionDialog(List<List<dynamic>> rows) async {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int selectedRow = 0; // Default to first row
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Header Row'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7, // Use 70% of screen height
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Choose which row contains the column headers:'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: selectedRow,
                      isExpanded: true,
                      items: List.generate(
                        rows.length > 15 ? 15 : rows.length, // Show up to 15 rows in dropdown
                        (index) => DropdownMenuItem<int>(
                          value: index,
                          child: Text('Row ${index + 1}'),
                        ),
                      ),
                      onChanged: (int? value) {
                        if (value != null) {
          setState(() {
                            selectedRow = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Preview:'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show selected header
                            Container(
                              color: Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: selectedRow < rows.length
                                      ? rows[selectedRow].map<Widget>((cell) => 
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            width: 150,
                                            child: Text(
                                              cell.toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        ).toList()
                                      : [const Text('No data')],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Show data rows with vertical and horizontal scrolling
                            Expanded(
                              child: rows.length > 1
                                ? SingleChildScrollView(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Show data rows (skip the selected header row)
                                          ...rows.asMap().entries
                                              .where((entry) => entry.key != selectedRow)
                                              .take(20) // Show up to 20 rows
                                              .map((entry) {
                                                final rowIndex = entry.key;
                                                final rowData = entry.value;
                                                
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(color: Colors.grey.shade300),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Row number
                                                      Container(
                                                        width: 50,
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Text(
                                                          'Row ${rowIndex + 1}',
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      // Row data
                                                      ...rowData.map<Widget>((cell) => 
                                                        Container(
                                                          width: 150,
                                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                                          child: Text(
                                                            cell.toString(),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        )
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                        ],
                                      ),
                                    ),
                                  )
                                : const Center(child: Text('No data rows')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedRow),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Helper for showing simple messages
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () async {
                  // Show confirmation dialog
                  final bool confirm = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete All Mappings?'),
                        content: const Text(
                          'Are you sure you want to delete all bank mappings? '
                          'This action cannot be undone.'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete All'),
                          ),
                        ],
                      );
                    },
                  ) ?? false;
                  
                  if (confirm) {
                    try {
                      final success = await _fileService.deleteAllBankMappings();
                      Navigator.of(context).pop(); // Close debug dialog
                      
                      if (success) {
                        _showMessage('All bank mappings deleted successfully');
                        // Refresh the bank list
                        _loadBanks();
                      } else {
                        _showMessage('Failed to delete bank mappings');
                      }
                    } catch (e) {
                      _showMessage('Error deleting mappings: $e');
                    }
                  }
                },
                child: const Text('Delete All Mappings'),
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
  
  void _showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    setState(() { 
      _isLoading = false;
      _filePath = null;
    });
  }

  // Check if current month data is outdated and needs archiving
  Future<void> _checkCurrentMonthData() async {
    try {
      // Get current month data file from FileService
      final currentMonthFile = await _fileService.getCurrentMonthFile();
      
      // If file doesn't exist, nothing to archive
      if (!await currentMonthFile.exists()) {
        return;
      }
      
      // Read the current month data
      final jsonString = await currentMonthFile.readAsString();
      final data = jsonDecode(jsonString);
      
      // Check if data contains a date field we can use
      if (!data.containsKey('month') || !data.containsKey('year')) {
        print('Current month data format does not contain month/year fields');
        return;
      }
      
      // Get stored month/year and current month/year
      final storedMonth = data['month'] as int;
      final storedYear = data['year'] as int;
      
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      
      // Check if data is from a previous month
      final isOutdated = (currentYear > storedYear) || 
                         (currentYear == storedYear && currentMonth > storedMonth);
      
      if (isOutdated && mounted) {
        // Show dialog to prompt archiving
        _showArchiveDialog(storedMonth, storedYear);
      }
    } catch (e) {
      print('Error checking current month data: $e');
    }
  }
  
  // Show dialog to confirm archiving
  void _showArchiveDialog(int month, int year) {
    // Format month name
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = monthNames[month - 1];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archive Previous Month Data'),
          content: Text(
            'Data from $monthName $year was detected. Would you like to archive '
            'this data to your yearly records and start fresh for the current month?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                _archiveCurrentMonthData(); // Process the archive
              },
              child: const Text('Archive Data'),
            ),
          ],
        );
      },
    );
  }
  
  // Archive current month data to yearly storage
  Future<void> _archiveCurrentMonthData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get the yearly data repository
      final yearlyRepo = YearlyDataRepository();
      await yearlyRepo.initialize();
      
      // Read current month data
      final currentMonthFile = await _fileService.getCurrentMonthFile();
      final jsonString = await currentMonthFile.readAsString();
      final data = jsonDecode(jsonString);
      
      // Extract transactions from current month data
      List<Transaction> transactions = [];
      if (data.containsKey('transactions') && data['transactions'] is List) {
        final transactionsList = data['transactions'] as List;
        transactions = transactionsList
            .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      
      if (transactions.isEmpty) {
        _showMessage('No transactions found to archive.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Save transactions to yearly data
      final success = await yearlyRepo.saveTransactions(transactions);
      
      // If successful, clear current month file by writing an empty structure
      if (success) {
        final now = DateTime.now();
        final emptyData = {
          'month': now.month,
          'year': now.year,
          'transactions': [],
          'lastUpdated': now.toIso8601String(),
        };
        
        await currentMonthFile.writeAsString(jsonEncode(emptyData));
        
        _showMessage('Successfully archived ${transactions.length} transactions to yearly data.');
      } else {
        _showMessage('Error archiving transactions. Please try again.');
      }
      
    } catch (e) {
      print('Error archiving current month data: $e');
      _showMessage('Error archiving data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create test data for archiving feature
  Future<void> _createTestDataForArchiving() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Create test transactions (for previous month)
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15); // Middle of last month
      
      // Test transactions with different amounts and types
      final testTransactions = [
        Transaction(
          id: 'test1-${DateTime.now().millisecondsSinceEpoch}',
          amount: 1500.0,
          date: lastMonth,
          description: 'SALA Lohn/Gehalt Monthly Salary',
          bankName: 'Deutsche Bank',
        ),
        Transaction(
          id: 'test2-${DateTime.now().millisecondsSinceEpoch}',
          amount: -89.99,
          date: lastMonth.add(const Duration(days: 2)),
          description: 'Amazon.de Purchase',
          bankName: 'Deutsche Bank',
        ),
        Transaction(
          id: 'test3-${DateTime.now().millisecondsSinceEpoch}',
          amount: -45.75,
          date: lastMonth.add(const Duration(days: 5)),
          description: 'REWE Supermarket',
          bankName: 'Deutsche Bank',
        ),
        Transaction(
          id: 'test4-${DateTime.now().millisecondsSinceEpoch}',
          amount: -129.99,
          date: lastMonth.add(const Duration(days: 7)),
          description: 'Monthly Rent Payment',
          bankName: 'Deutsche Bank',
        ),
        Transaction(
          id: 'test5-${DateTime.now().millisecondsSinceEpoch}',
          amount: -19.99,
          date: lastMonth.add(const Duration(days: 10)),
          description: 'Netflix Subscription',
          bankName: 'Deutsche Bank',
        ),
      ];
      
      // Create current_month.json file with previous month's data
      final file = await _fileService.getCurrentMonthFile();
      
      // Create the JSON structure
      final previousMonthData = {
        'month': lastMonth.month,
        'year': lastMonth.year,
        'transactions': testTransactions.map((t) => t.toJson()).toList(),
        'lastUpdated': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      };
      
      // Write to file
      await file.writeAsString(jsonEncode(previousMonthData));
      
      // Show success message
      _showMessage('Created test data for ${_getMonthName(lastMonth.month)} ${lastMonth.year}. Restart the app to see the archive prompt.');
      
    } catch (e) {
      print('Error creating test data for archiving: $e');
      _showMessage('Error creating test data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Helper to get month name from number
  String _getMonthName(int month) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  // Check data integrity and show results
  Future<void> _checkDataIntegrity() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current year
      final now = DateTime.now();
      final currentYear = now.year;
      
      // Verify data consistency for current year
      final consistencyResults = await _fileService.verifyDataConsistency(currentYear);
      
      // Check if repair is needed
      final needsRepair = consistencyResults.isNotEmpty && 
                         (consistencyResults.containsKey('summaryIssues') || 
                          consistencyResults.containsKey('error'));
      
      // Show results dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Data Integrity Check'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (consistencyResults.isEmpty)
                    const Text('✅ All data is consistent and valid.', 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  
                  if (consistencyResults.containsKey('error'))
                    Text('❌ Error checking data: ${consistencyResults['error']}',
                      style: const TextStyle(color: Colors.red)),
                  
                  if (consistencyResults.containsKey('summaryIssues')) ...[
                    const Text('⚠️ Issues found in yearly summary:',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    ...(consistencyResults['summaryIssues'] as List<String>).map((issue) => 
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text('• $issue', style: const TextStyle(color: Colors.orange)),
                      )
                    ),
                    
                    const SizedBox(height: 8),
                    const Text('Recalculated values from monthly data:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    
                    if (consistencyResults.containsKey('recalculatedValues')) ...[
                      _buildValueRow('Total Income', 
                        (consistencyResults['recalculatedValues'] as Map)['totalIncome']),
                      _buildValueRow('Total Expenses', 
                        (consistencyResults['recalculatedValues'] as Map)['totalExpenses']),
                      _buildValueRow('Total Savings', 
                        (consistencyResults['recalculatedValues'] as Map)['totalSavings']),
                      _buildValueRow('Transaction Count', 
                        (consistencyResults['recalculatedValues'] as Map)['transactionCount']),
                    ],
                  ],
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
              if (needsRepair)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _repairDataIntegrity(currentYear);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Repair Data'),
                ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error checking data integrity: $e');
      _showMessage('Error checking data integrity: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Helper to build value row for integrity check results
  Widget _buildValueRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value.toString()),
        ],
      ),
    );
  }
  
  // Repair data integrity issues
  Future<void> _repairDataIntegrity(int year) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Repair'),
            content: const Text(
              'This will recalculate yearly summaries based on monthly data. '
              'A backup will be created before making changes. Continue?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Repair'),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Perform repair
      final result = await _fileService.repairYearlyData(year);
      
      // Show result
      if (result.containsKey('success') && result['success'] == true) {
        _showMessage(result['message'] ?? 'Data repair completed successfully.');
        
        // Reload data after successful repair
        await _loadData();
      } else {
        _showMessage(result['error'] ?? 'Error repairing data. Please try again.');
      }
      
    } catch (e) {
      print('Error repairing data: $e');
      _showMessage('Error repairing data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load data for the home screen
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize storage if needed
      await _fileService.initializeStorage();
      
      // Get the yearly data repository
      final yearlyRepo = YearlyDataRepository();
      await yearlyRepo.initialize();
      
      // Get yearly data
      final now = DateTime.now();
      final currentYear = now.year;
      print('Loading yearly data for year: $currentYear');
      
      final yearData = await yearlyRepo.getYearlyData(currentYear);
      print('Yearly data loaded successfully: ${yearData != null}');
      
      if (yearData != null) {
        print('Yearly summary: Income=${yearData.summary.totalIncome}, Expenses=${yearData.summary.totalExpenses}');
        print('Months available: ${yearData.months.keys.toList()}');
        print('Number of transactions: ${yearData.summary.transactionCount}');
      }
      
      if (mounted) {
        setState(() {
          _yearlyData = yearData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show validation dialog for bank mappings
  Future<void> _showBankValidationDialog() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Check for bank mapping issues
      final issues = await _fileService.validateAllBankMappings();
      
      setState(() {
        _isLoading = false;
      });
      
      if (issues.isEmpty) {
        _showMessage('All bank mappings are valid');
        return;
      }
      
      // Show dialog with issues
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Bank Mapping Issues'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('The following issues were found:'),
                    const SizedBox(height: 10),
                    ...issues.entries.map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('  ${entry.value}'),
                          ],
                        ),
                      )
                    ).toList(),
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
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDebugDialog(); // Open the debug dialog
                  },
                  child: const Text('Show Debug Info'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error validating bank mappings: $e');
    }
  }
} 