import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/bank_mapping.dart'; // Import the model
import '../models/transaction.dart';
import '../models/category_mapping.dart';
import 'package:csv/csv.dart';
import '../models/monthly_data.dart';
import '../models/yearly_data.dart';
import 'file_integrity_service.dart'; // Import our new integrity service
import 'package:path/path.dart' as path;

class FileService {
  // Store our base directory once we've found a working one
  Directory? _baseDirectory;
  
  // File integrity service instance
  final FileIntegrityService _integrityService = FileIntegrityService();
  
  // --- Directory Paths ---

  // Initializer method that should be called when app starts
  Future<bool> initializeStorage() async {
    try {
      // On Android, try the known working path first
      if (Platform.isAndroid) {
        try {
          // Try the path that's working from logs
          final internalDir = Directory('/data/data/com.example.pennypilot/cache');
          if (await internalDir.exists() && await _testDirectory(internalDir)) {
            print('Using Android internal cache directly');
            return true;
          }
        } catch (e) {
          print('Error using direct Android cache path: $e');
        }
      }
      
      // Only try these if the direct Android path doesn't work
      
      // 1. Application Documents Directory
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        if (await _testDirectory(appDocDir)) {
          return true;
        }
      } catch (e) {
        print('Error using application documents directory: $e');
      }
      
      // 2. External Storage Directory (nullable)
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null && await _testDirectory(externalDir)) {
          return true;
        }
      } catch (e) {
        print('Error using external storage directory: $e');
      }
      
      // 3. Temporary Directory
      try {
        final tempDir = await getTemporaryDirectory();
        if (await _testDirectory(tempDir)) {
          return true;
        }
      } catch (e) {
        print('Error using temporary directory: $e');
      }
      
      // 4. Application Support Directory
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        if (await _testDirectory(appSupportDir)) {
          return true;
        }
      } catch (e) {
        print('Error using application support directory: $e');
      }
      
      // If all methods failed, create directory directly in the app's data directory
      if (Platform.isAndroid) {
        try {
          // Create all the cache directories we could potentially use
          final List<String> possiblePaths = [
            '/data/data/com.example.pennypilot/cache',
            '/data/user/0/com.example.pennypilot/cache',
            '/storage/emulated/0/Android/data/com.example.pennypilot/cache',
            // Add our own custom directories that should definitely be writable
            '/data/data/com.example.pennypilot/app_banks',
            '/data/data/com.example.pennypilot/app_data',
            '/data/data/com.example.pennypilot/files'
          ];
          
          for (final path in possiblePaths) {
            try {
              final dir = Directory(path);
              if (!await dir.exists()) {
                await dir.create(recursive: true);
              }
              
              if (await _testDirectory(dir)) {
                return true;
              }
            } catch (e) {
              print('Failed to create/use directory at $path: $e');
            }
          }
        } catch (e) {
          print('Error using Android data paths: $e');
        }
      }
      
      print('Failed to find any writable directory');
      return false;
    } catch (e) {
      print('Error initializing storage: $e');
      return false;
    }
  }
  
  // Test if a directory is writable and set it as the base directory if it is
  Future<bool> _testDirectory(Directory dir) async {
    try {
      // Test write access
      final testFile = File('${dir.path}/test_write.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      // If we get here, we found a writable directory
      _baseDirectory = dir;
      print('Using directory for storage: ${dir.path}');
      
      // Create subdirectories
      await _ensureSubdirectories();
      return true;
    } catch (e) {
      print('Directory ${dir.path} is not writable: $e');
      return false;
    }
  }
  
  // Create all subdirectories we need
  Future<void> _ensureSubdirectories() async {
    if (_baseDirectory == null) {
      throw Exception('Base directory not initialized');
    }
    
    final basePath = _baseDirectory!.path;
    
    // Create each subdirectory
    final dirs = [
      Directory('$basePath/banks'),
      Directory('$basePath/data'),
      Directory('$basePath/mappings')
    ];
    
    for (var dir in dirs) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  // Get base path for app storage
  Future<String> get _localPath async {
    if (_baseDirectory != null) {
      return _baseDirectory!.path;
    }
    
    // If not initialized, try to initialize
    bool success = await initializeStorage();
    if (success && _baseDirectory != null) {
      return _baseDirectory!.path;
    }
    
    throw Exception('Could not initialize storage - no writable location found');
  }

  // Public method to access data directory
  Future<Directory> getDataDirectory() async {
    return await _dataDirectory;
  }

  Future<Directory> get _banksDirectory async {
    try {
      final path = await _localPath;
      final banksDir = Directory('$path/banks');
      
      // Try to create the directory
      try {
        if (!await banksDir.exists()) {
          await banksDir.create(recursive: true);
        }
        
        // Test if we can write to it with better error handling
        try {
          final testFile = File('${banksDir.path}/test.tmp');
          await testFile.writeAsString('test');
          await testFile.delete();
          
          return banksDir;
        } catch (e) {
          print('Error writing test file to banks directory: $e');
          // Continue to alternate location rather than immediately throwing
        }
      } catch (e) {
        print('Error creating banks directory: $e');
        // Continue to alternate location
      }
      
      // Try both known working paths specifically for Android
      final List<String> possiblePaths = [
        '/data/data/com.example.pennypilot/cache/banks',
        '/data/user/0/com.example.pennypilot/cache/banks',
        '$path/banks' // Include original path as well
      ];
      
      // Try each alternate location in sequence
      for (final dirPath in possiblePaths) {
        try {
          final directory = Directory(dirPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          // Verify we can write to the directory
          final testFile = File('${directory.path}/test.tmp');
          await testFile.writeAsString('test');
          await testFile.delete();
          
          print('Using banks directory: ${directory.path}');
          return directory;
        } catch (e) {
          print('Error trying alternate path $dirPath: $e');
          // Continue to next path
        }
      }
      
      // If all direct paths fail, use app's cache directory as last resort
      try {
        final cacheDir = await getTemporaryDirectory();
        final alternateBanksDir = Directory('${cacheDir.path}/banks');
        if (!await alternateBanksDir.exists()) {
          await alternateBanksDir.create(recursive: true);
        }
        
        // Verify we can write to the alternate directory
        final testFile = File('${alternateBanksDir.path}/test.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        
        print('Using fallback banks directory: ${alternateBanksDir.path}');
        return alternateBanksDir;
      } catch (e) {
        print('Error creating alternate banks directory: $e');
        throw Exception('Cannot find a writable directory for bank data');
      }
    } catch (e) {
      print('Error in _banksDirectory: $e');
      throw e;
    }
  }

  Future<Directory> get _dataDirectory async {
    try {
    final path = await _localPath;
    final dataDir = Directory('$path/data');
      
      try {
     if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
      } catch (e) {
        print('Error creating data directory: $e');
        
        // Fallback to temporary directory
        final cacheDir = await getTemporaryDirectory();
        final alternateDataDir = Directory('${cacheDir.path}/data');
        if (!await alternateDataDir.exists()) {
          await alternateDataDir.create(recursive: true);
        }
        print('Using alternate data directory: ${alternateDataDir.path}');
        return alternateDataDir;
      }
    } catch (e) {
      print('Error in _dataDirectory: $e');
      throw e;
    }
  }

   Future<Directory> get _mappingsDirectory async {
    try {
    final path = await _localPath;
    final mapDir = Directory('$path/mappings');
      
      try {
     if (!await mapDir.exists()) {
      await mapDir.create(recursive: true);
    }
    return mapDir;
      } catch (e) {
        print('Error creating mappings directory: $e');
        
        // Fallback to temporary directory
        final cacheDir = await getTemporaryDirectory();
        final alternateMapDir = Directory('${cacheDir.path}/mappings');
        if (!await alternateMapDir.exists()) {
          await alternateMapDir.create(recursive: true);
        }
        print('Using alternate mappings directory: ${alternateMapDir.path}');
        return alternateMapDir;
      }
    } catch (e) {
      print('Error in _mappingsDirectory: $e');
      throw e;
    }
  }


  // --- Bank Mapping Files ---

  Future<File> getBankMappingFile(String bankName) async {
    // Sanitize bank name for filename (replace spaces, etc.) - simple example
    final sanitizedName = bankName.replaceAll(RegExp(r'[^\w\.-]+'), '_');
    final dir = await _banksDirectory;
    return File('${dir.path}/$sanitizedName.json');
  }

  /// Delete all bank mappings - useful for troubleshooting
  Future<bool> deleteAllBankMappings() async {
    try {
      final dir = await _banksDirectory;
      if (!await dir.exists()) {
        print('Banks directory does not exist');
        return true; // Nothing to delete
      }
      
      final List<FileSystemEntity> files = dir.listSync();
      int deletedCount = 0;
      
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            await entity.delete();
            print('Deleted mapping file: ${entity.path}');
            deletedCount++;
          } catch (e) {
            print('Error deleting file ${entity.path}: $e');
          }
        }
      }
      
      print('Deleted $deletedCount bank mapping files');
      return true;
    } catch (e) {
      print('Error deleting bank mappings: $e');
      return false;
    }
  }

  Future<bool> saveBankMapping(BankMapping mapping) async {
    try {
      final file = await getBankMappingFile(mapping.bankName);
      final jsonData = mapping.toJson(); // Use generated toJson
      
      // Use direct write without integrity check to simplify
      await file.writeAsString(jsonEncode(jsonData), flush: true);
      print('Mapping saved to: ${file.path}');
      
      // Verify the file was saved by trying to read it back
      if (await file.exists()) {
        try {
          await file.readAsString();
          return true;
        } catch (e) {
          print('Warning: Mapping saved but couldn\'t be read back: $e');
          // Continue with alternative paths
        }
      }
      
      // Try alternate known paths if default didn't work
      final List<String> possiblePaths = [
        '/data/data/com.example.pennypilot/cache/banks',
        '/data/user/0/com.example.pennypilot/cache/banks'
      ];
      
      // Try saving to each path directly
      for (final dirPath in possiblePaths) {
        try {
          final directory = Directory(dirPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          final sanitizedName = mapping.bankName.replaceAll(RegExp(r'[^\w\.-]+'), '_');
          final alternateFile = File('${dirPath}/$sanitizedName.json');
          
          await alternateFile.writeAsString(jsonEncode(jsonData), flush: true);
          print('Mapping saved to alternate path: ${alternateFile.path}');
          return true;
        } catch (e) {
          print('Error saving to alternate path: $e');
          // Continue to next path
        }
      }
      
      print('Warning: Tried all paths but couldn\'t verify mapping was saved');
      return false;
    } catch (e) {
      print('Error saving bank mapping: $e');
      // Return false instead of rethrowing
      return false;
    }
  }

  Future<BankMapping?> loadBankMapping(String bankName) async {
    try {
      final file = await getBankMappingFile(bankName);
      if (await file.exists()) {
        // Try direct read first, then fall back to integrity service if needed
        String jsonString;
        try {
          // First try to read directly from the file
          jsonString = await file.readAsString();
          print('Successfully loaded bank mapping from: ${file.path}');
        } catch (e) {
          print('Error reading bank mapping directly: $e');
          // Try alternate paths instead of immediately returning null
          jsonString = await _tryReadFromAlternatePaths(bankName);
          if (jsonString.isEmpty) {
            return null;
          }
        }
        
        // Parse the JSON
        try {
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          
          // Fix for compatibility with old DateFormatType enum format
          if (jsonMap.containsKey('dateFormatType') && jsonMap['dateFormatType'] != null) {
            // Convert old format (named with camelCase) to new format (lowercase)
            final oldFormat = jsonMap['dateFormatType'] as int;
            
            // Map the old enum index to the new enum index
            jsonMap['dateFormatType'] = oldFormat;
          }
          
          return BankMapping.fromJson(jsonMap);
        } catch (e) {
          print('Error parsing bank mapping JSON: $e');
          return null;
        }
      } else {
        print('Bank mapping file does not exist at primary location for $bankName');
        // Try alternate paths
        final jsonString = await _tryReadFromAlternatePaths(bankName);
        if (jsonString.isNotEmpty) {
          try {
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            if (jsonMap.containsKey('dateFormatType') && jsonMap['dateFormatType'] != null) {
              final oldFormat = jsonMap['dateFormatType'] as int;
              jsonMap['dateFormatType'] = oldFormat;
            }
            return BankMapping.fromJson(jsonMap);
          } catch (e) {
            print('Error parsing bank mapping from alternate path: $e');
          }
        }
        return null;
      }
    } catch (e) {
      print('Error loading bank mapping for $bankName: $e');
      return null;
    }
  }
  
  // Helper method to try reading from alternate paths
  Future<String> _tryReadFromAlternatePaths(String bankName) async {
    final sanitizedName = bankName.replaceAll(RegExp(r'[^\w\.-]+'), '_');
    final List<String> possiblePaths = [
      '/data/data/com.example.pennypilot/cache/banks',
      '/data/user/0/com.example.pennypilot/cache/banks'
    ];
    
    for (final dirPath in possiblePaths) {
      try {
        final alternateFile = File('${dirPath}/$sanitizedName.json');
        if (await alternateFile.exists()) {
          final content = await alternateFile.readAsString();
          print('Successfully loaded bank mapping from alternate path: ${alternateFile.path}');
          return content;
        }
      } catch (e) {
        print('Error trying to read from alternate path: $e');
      }
    }
    
    return ''; // Return empty string if no file found
  }

  Future<List<String>> listSavedBankNames() async {
    Set<String> bankNames = {}; // Use a Set to avoid duplicates
    
    try {
      // Try to get directory with additional error handling
      Directory? dir;
      try {
        dir = await _banksDirectory;
        await _addBankNamesFromDirectory(dir, bankNames);
      } catch (e) {
        print('Error getting primary banks directory: $e');
        // Continue to alternate directories
      }
      
      // Also check known alternate paths directly
      final List<String> alternatePaths = [
        '/data/data/com.example.pennypilot/cache/banks',
        '/data/user/0/com.example.pennypilot/cache/banks'
      ];
      
      for (final dirPath in alternatePaths) {
        try {
          final directory = Directory(dirPath);
          if (await directory.exists()) {
            await _addBankNamesFromDirectory(directory, bankNames);
          }
        } catch (e) {
          print('Error checking alternate path $dirPath: $e');
        }
      }
      
      // Convert to sorted List
      final sortedNames = bankNames.toList();
      sortedNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      return sortedNames;
    } catch (e) {
      print('Error listing saved bank names: $e');
      return []; // Return empty list on error
    }
  }
  
  // Helper method to extract bank names from a directory
  Future<void> _addBankNamesFromDirectory(Directory dir, Set<String> bankNames) async {
    if (!await dir.exists()) {
      print('Directory ${dir.path} does not exist');
      return;
    }
    
    List<FileSystemEntity> files;
    try {
      files = dir.listSync();
    } catch (e) {
      print('Error listing files in directory ${dir.path}: $e');
      return;
    }
    
    for (var fileEntity in files) {
      if (fileEntity is File && fileEntity.path.endsWith('.json')) {
        try {
          final jsonString = await fileEntity.readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          
          // Try to fix compatibility issues before parsing
          if (jsonMap.containsKey('dateFormatType') && jsonMap['dateFormatType'] != null) {
            final oldFormat = jsonMap['dateFormatType'] as int;
            jsonMap['dateFormatType'] = oldFormat;
          }
          
          if (jsonMap.containsKey('bankName')) {
            final String bankName = jsonMap['bankName'] as String;
            bankNames.add(bankName);
          }
        } catch (e) {
          print("Error reading bank mapping from ${fileEntity.path}: $e");
        }
      }
    }
  }

  // --- Category Mapping Files ---
  
  Future<File> getCategoryMappingFile(String keyword) async {
    // Sanitize keyword for filename
    final sanitizedName = keyword.replaceAll(RegExp(r'[^\w\.-]+'), '_');
    final dir = await _mappingsDirectory;
    return File('${dir.path}/$sanitizedName.json');
  }
  
  Future<bool> saveCategoryMapping(CategoryMapping mapping) async {
    try {
      final file = await getCategoryMappingFile(mapping.keyword);
      final jsonString = jsonEncode(mapping.toJson());
      
      // Attempt to write to primary directory
      await file.writeAsString(jsonString);
      print('Category mapping saved to: ${file.path}');
      
      // Verify the file was saved by trying to read it back
      if (await file.exists()) {
        try {
          await file.readAsString();
          return true;
        } catch (e) {
          print('Warning: Category mapping saved but couldn\'t be read back: $e');
          // Continue with alternative paths
        }
      }
      
      // Try alternate known paths if default didn't work
      final List<String> possiblePaths = [
        '/data/data/com.example.pennypilot/cache/mappings',
        '/data/user/0/com.example.pennypilot/cache/mappings',
        '/storage/emulated/0/Android/data/com.example.pennypilot/files/mappings'
      ];
      
      // Try saving to each path directly
      for (final dirPath in possiblePaths) {
        try {
          final directory = Directory(dirPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          final sanitizedName = mapping.keyword.replaceAll(RegExp(r'[^\w\.-]+'), '_');
          final alternateFile = File('${dirPath}/$sanitizedName.json');
          
          await alternateFile.writeAsString(jsonString);
          print('Category mapping saved to alternate path: ${alternateFile.path}');
          return true;
        } catch (e) {
          print('Error saving category mapping to alternate path: $e');
          // Continue to next path
        }
      }
      
      print('Warning: Tried all paths but couldn\'t verify category mapping was saved');
      return false;
    } catch (e) {
      print('Error saving category mapping: $e');
      return false; // Return false instead of rethrowing
    }
  }
  
  Future<bool> deleteCategoryMapping(String keyword) async {
    try {
      bool deleted = false;
      
      // Try primary file first
      final file = await getCategoryMappingFile(keyword);
      if (await file.exists()) {
        await file.delete();
        print('Category mapping deleted: ${file.path}');
        deleted = true;
      }
      
      // Also check known alternate paths
      final sanitizedName = keyword.replaceAll(RegExp(r'[^\w\.-]+'), '_');
      final List<String> alternatePaths = [
        '/data/data/com.example.pennypilot/cache/mappings',
        '/data/user/0/com.example.pennypilot/cache/mappings',
        '/storage/emulated/0/Android/data/com.example.pennypilot/files/mappings'
      ];
      
      for (final dirPath in alternatePaths) {
        try {
          final alternateFile = File('${dirPath}/$sanitizedName.json');
          if (await alternateFile.exists()) {
            await alternateFile.delete();
            print('Category mapping deleted from alternate path: ${alternateFile.path}');
            deleted = true;
          }
        } catch (e) {
          print('Error deleting category mapping from $dirPath: $e');
        }
      }
      
      return deleted;
    } catch (e) {
      print('Error deleting category mapping: $e');
      return false;
    }
  }
  
  Future<CategoryMapping?> loadCategoryMapping(String keyword) async {
    try {
      // Try primary file first
      final file = await getCategoryMappingFile(keyword);
      if (await file.exists()) {
        try {
          final jsonString = await file.readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          return CategoryMapping.fromJson(jsonMap);
        } catch (e) {
          print('Error reading category mapping directly: $e');
          // Continue to try alternate paths
        }
      }
      
      // Try alternate paths
      final sanitizedName = keyword.replaceAll(RegExp(r'[^\w\.-]+'), '_');
      final List<String> alternatePaths = [
        '/data/data/com.example.pennypilot/cache/mappings',
        '/data/user/0/com.example.pennypilot/cache/mappings',
        '/storage/emulated/0/Android/data/com.example.pennypilot/files/mappings'
      ];
      
      for (final dirPath in alternatePaths) {
        try {
          final alternateFile = File('${dirPath}/$sanitizedName.json');
          if (await alternateFile.exists()) {
            final jsonString = await alternateFile.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            print('Category mapping loaded from alternate path: ${alternateFile.path}');
            return CategoryMapping.fromJson(jsonMap);
          }
        } catch (e) {
          print('Error loading category mapping from $dirPath: $e');
        }
      }
      
      return null;
    } catch (e) {
      print('Error loading category mapping for $keyword: $e');
      return null;
    }
  }
  
  Future<List<CategoryMapping>> loadAllCategoryMappings() async {
    // Use a map to ensure unique mappings by keyword
    Map<String, CategoryMapping> uniqueMappings = {};
    Set<String> processedFiles = {}; // Track already processed files
    
    try {
      // Try primary directory first
      try {
        final dir = await _mappingsDirectory;
        if (await dir.exists()) {
          await _loadMappingsFromDirectory(dir, uniqueMappings, processedFiles);
        }
      } catch (e) {
        print('Error loading mappings from primary directory: $e');
      }
      
      // Try alternate paths
      final List<String> alternatePaths = [
        '/data/data/com.example.pennypilot/cache/mappings',
        '/data/user/0/com.example.pennypilot/cache/mappings',
        '/storage/emulated/0/Android/data/com.example.pennypilot/files/mappings'
      ];
      
      for (final dirPath in alternatePaths) {
        try {
          final directory = Directory(dirPath);
          if (await directory.exists()) {
            await _loadMappingsFromDirectory(directory, uniqueMappings, processedFiles);
          }
        } catch (e) {
          print('Error loading mappings from alternate path $dirPath: $e');
        }
      }
      
      // Return only unique mappings as a list
      return uniqueMappings.values.toList();
    } catch (e) {
      print('Error loading all category mappings: $e');
      return uniqueMappings.values.toList(); // Return whatever we've loaded so far
    }
  }
  
  // Helper method to load mappings from a directory
  Future<void> _loadMappingsFromDirectory(
    Directory dir, 
    Map<String, CategoryMapping> uniqueMappings, 
    Set<String> processedFiles
  ) async {
    try {
      final files = await dir.list().where((entity) => 
        entity is File && entity.path.endsWith('.json')
      ).toList();
      
      for (var file in files) {
        try {
          // Skip files we've already processed
          if (processedFiles.contains(file.path)) continue;
          
          final jsonString = await (file as File).readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          
          // Mark file as processed
          processedFiles.add(file.path);
          
          final mapping = CategoryMapping.fromJson(jsonMap);
          
          // Add to unique mappings map by keyword
          uniqueMappings[mapping.keyword] = mapping;
          print('Loaded category mapping for keyword "${mapping.keyword}" from: ${file.path}');
        } catch (e) {
          print('Error loading category mapping from ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error listing files in directory ${dir.path}: $e');
    }
  }

  // --- Transaction Files ---
  
  Future<File> getTransactionFile(String id) async {
    final dir = await _dataDirectory;
    return File('${dir.path}/transaction_$id.json');
  }
  
  Future<File> getTransactionIndexFile() async {
    final dir = await _dataDirectory;
    return File('${dir.path}/transaction_index.json');
  }
  
  Future<void> saveTransaction(Transaction transaction) async {
    try {
      // Save the transaction file
      final file = await getTransactionFile(transaction.id);
      final jsonString = jsonEncode(transaction.toJson());
      await file.writeAsString(jsonString);
      
      // Update the transaction index
      final indexFile = await getTransactionIndexFile();
      Map<String, dynamic> index = {};
      
      if (await indexFile.exists()) {
        final indexString = await indexFile.readAsString();
        index = jsonDecode(indexString) as Map<String, dynamic>;
      }
      
      // Add to index with timestamp
      index[transaction.id] = {
        'year': transaction.date.year,
        'month': transaction.date.month,
        'categorySet': transaction.category != null,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await indexFile.writeAsString(jsonEncode(index));
      
      // Update the yearly data file if this is an existing transaction
      final year = transaction.date.year;
      final month = transaction.date.month;
      
      // Update the current month's data if this transaction is from the current month
      final now = DateTime.now();
      if (year == now.year && month == now.month) {
        await _updateCurrentMonthTransaction(transaction);
      }
      
      // Update yearly data 
      await _updateYearlyDataForTransaction(transaction);
      
      print('Transaction ${transaction.id} saved successfully');
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }
  
  /// Updates the current month's data with a new transaction
  Future<void> _updateCurrentMonthTransaction(Transaction transaction) async {
    try {
      final currentMonthFile = await _getCurrentMonthFile();
      final year = transaction.date.year;
      final month = transaction.date.month;
      
      // Load existing data or create new
      MonthlyData monthlyData;
      if (await currentMonthFile.exists()) {
        final jsonString = await currentMonthFile.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        monthlyData = MonthlyData.fromJson(jsonMap);
      } else {
        monthlyData = MonthlyData.empty(year, month);
      }
      
      // Check if transaction already exists, replace it or add it
      final existingIndex = monthlyData.transactions.indexWhere((t) => t.id == transaction.id);
      if (existingIndex >= 0) {
        // Replace the transaction
        final updatedTransactions = List<Transaction>.from(monthlyData.transactions);
        updatedTransactions[existingIndex] = transaction;
        monthlyData = monthlyData.updateTransactions(updatedTransactions);
      } else {
        // Add new transaction
        monthlyData = monthlyData.addTransaction(transaction);
      }
      
      // Save updated data
      final jsonString = jsonEncode(monthlyData.toJson());
      await currentMonthFile.writeAsString(jsonString);
    } catch (e) {
      print('Error updating current month data: $e');
      // Continue with other updates even if this fails
    }
  }
  
  /// Updates the yearly data file with a transaction
  Future<void> _updateYearlyDataForTransaction(Transaction transaction) async {
    try {
      final year = transaction.date.year;
      final month = transaction.date.month;
      
      // Get the yearly data file
      final file = await _getYearlyDataFile(year);
      
      // Load existing data or create new
      YearlyData yearlyData;
      if (await file.exists()) {
        // Use safe read with validation
        final jsonMap = await _integrityService.safeReadJson(file);
        
        if (jsonMap != null) {
          yearlyData = YearlyData.fromJson(jsonMap);
        } else {
          // If read fails, create new data
          yearlyData = YearlyData.empty(year);
        }
      } else {
        yearlyData = YearlyData.empty(year);
      }
      
      // Get the monthly data
      MonthlyData monthlyData = yearlyData.getMonth(month);
      
      // Check if transaction already exists, replace it or add it
      final existingIndex = monthlyData.transactions.indexWhere((t) => t.id == transaction.id);
      if (existingIndex >= 0) {
        // Replace the transaction
        final updatedTransactions = List<Transaction>.from(monthlyData.transactions);
        updatedTransactions[existingIndex] = transaction;
        monthlyData = monthlyData.updateTransactions(updatedTransactions);
      } else {
        // Add new transaction
        monthlyData = monthlyData.addTransaction(transaction);
      }
      
      // Update the month in yearly data
      yearlyData = yearlyData.updateMonth(month, monthlyData);
      
      // Save updated yearly data using safe write
      final jsonData = yearlyData.toJson();
      final success = await _integrityService.safeWriteJson(file, jsonData);
      
      if (!success) {
        print('Warning: Failed to safely write yearly data for year $year');
      }
    } catch (e) {
      print('Error updating yearly data: $e');
      // Continue with other operations even if this fails
    }
  }
  
  /// Verify data consistency between yearly and monthly files
  Future<Map<String, dynamic>> verifyDataConsistency(int year) async {
    try {
      // Get the yearly file
      final yearlyFile = await _getYearlyDataFile(year);
      
      // Check if yearly file exists
      if (!await yearlyFile.exists()) {
        return {'error': 'Yearly data file does not exist for $year', 'missingYearlyFile': true, 'year': year};
      }
      
      // Read yearly data
      final yearlyJsonMap = await _integrityService.safeReadJson(yearlyFile);
      if (yearlyJsonMap == null) {
        return {'error': 'Failed to read yearly data file for $year', 'year': year};
      }
      
      // Get all monthly files for this year
      final dir = await _dataDirectory;
      final directory = Directory(dir.path);
      final files = await directory
        .list()
        .where((entity) => 
          entity is File && 
          entity.path.contains('month_${year}_') && 
          entity.path.endsWith('.json') &&
          !entity.path.contains('backup')
        )
        .toList();
        
      final monthlyData = <Map<String, dynamic>>[];
      
      for (var entity in files) {
        final file = entity as File;
        final jsonMap = await _integrityService.safeReadJson(file);
        if (jsonMap != null) {
          monthlyData.add(jsonMap);
        }
      }
      
      // Verify consistency
      final result = _integrityService.verifyDataConsistency(
        yearlyJsonMap, 
        monthlyData
      );
      
      // Add year information to the result
      result['year'] = year;
      return result;
    } catch (e) {
      print('Error verifying data consistency for year $year: $e');
      return {'error': 'Error checking data for year $year: ${e.toString()}', 'year': year};
    }
  }
  
  /// Repair yearly data by reconstructing it from monthly files
  Future<Map<String, dynamic>> repairYearlyData(int year) async {
    try {
      // Get the yearly file
      final yearlyFile = await _getYearlyDataFile(year);
      
      // Backup existing yearly file if it exists
      if (await yearlyFile.exists()) {
        final backupFile = File('${yearlyFile.path}.backup.${DateTime.now().millisecondsSinceEpoch}');
        await yearlyFile.copy(backupFile.path);
        print('Backed up yearly file to ${backupFile.path}');
      }
      
      // Get all monthly files for this year
      final dir = await _dataDirectory;
      final directory = Directory(dir.path);
      final monthlyFiles = await directory
        .list()
        .where((entity) => 
          entity is File && 
          entity.path.contains('month_${year}_') && 
          entity.path.endsWith('.json') &&
          !entity.path.contains('backup')
        )
        .toList();
      
      // If no monthly files, create an empty yearly structure
      if (monthlyFiles.isEmpty) {
        final emptyYearlyData = YearlyData.empty(year);
        await _writeJson(yearlyFile, emptyYearlyData.toJson());
        return {'success': true, 'message': 'Created empty yearly data for $year as no monthly files were found', 'year': year};
      }
      
      // Start with empty yearly data
      YearlyData yearlyData = YearlyData.empty(year);
      
      // Read each monthly file and add to yearly data
      for (var entity in monthlyFiles) {
        try {
          final file = entity as File;
          final jsonMap = await _integrityService.safeReadJson(file);
          
          if (jsonMap != null) {
            // Extract month number from filename
            final fileNameOnly = path.basename(file.path);
            final monthMatch = RegExp(r'month_\d{4}_(\d{2})').firstMatch(fileNameOnly);
            
            if (monthMatch != null) {
              final monthStr = monthMatch.group(1);
              if (monthStr != null) {
                final month = int.parse(monthStr);
                
                // Convert to MonthlyData
                final monthlyData = MonthlyData.fromJson(jsonMap);
                
                // Update yearly data with this month
                yearlyData = yearlyData.updateMonth(month, monthlyData);
              }
            }
          }
        } catch (e) {
          print('Error processing monthly file ${entity.path}: $e');
        }
      }
      
      // Recalculate summary if we have monthly data
      if (yearlyData.months.isNotEmpty) {
        yearlyData = yearlyData.recalculateSummary(yearlyData.months);
      }
      
      // Write the repaired yearly data back to file
      await _writeJson(yearlyFile, yearlyData.toJson());
      
      return {
        'success': true, 
        'message': 'Successfully repaired yearly data for $year from ${yearlyData.months.length} monthly files', 
        'year': year
      };
    } catch (e) {
      print('Error repairing yearly data for $year: $e');
      return {'error': 'Error repairing data for year $year: ${e.toString()}', 'year': year};
    }
  }
  
  Future<File> _getCurrentMonthFile() async {
    final dir = await _dataDirectory;
    return File('${dir.path}/current_month.json');
  }
  
  Future<File> _getYearlyDataFile(int year) async {
    final dir = await _dataDirectory;
    return File('${dir.path}/$year.json');
  }
  
  Future<Transaction?> loadTransaction(String id) async {
    try {
      final file = await getTransactionFile(id);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return Transaction.fromJson(jsonMap);
      } else {
        return null;
      }
    } catch (e) {
      print('Error loading transaction $id: $e');
      return null;
    }
  }
  
  Future<List<Transaction>> loadAllTransactions() async {
    try {
      final indexFile = await getTransactionIndexFile();
      if (!await indexFile.exists()) {
        return [];
      }
      
      final indexString = await indexFile.readAsString();
      final index = jsonDecode(indexString) as Map<String, dynamic>;
      
      final List<Transaction> transactions = [];
      for (var id in index.keys) {
        final transaction = await loadTransaction(id);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }
      
      // Sort by date, newest first
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      print('Error loading all transactions: $e');
      return [];
    }
  }
  
  // --- Category List File ---
  
  Future<File> getCategoryListFile() async {
    final dir = await _dataDirectory;
    return File('${dir.path}/category_list.json');
  }
  
  Future<void> saveCategoryList(CategoryList categoryList) async {
    try {
      final file = await getCategoryListFile();
      final jsonString = jsonEncode(categoryList.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving category list: $e');
      rethrow;
    }
  }
  
  Future<CategoryList> loadCategoryList() async {
    try {
      final file = await getCategoryListFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return CategoryList.fromJson(jsonMap);
      } else {
        // If no category list exists, create a default one and save it
        final defaultList = CategoryList.getDefault();
        await saveCategoryList(defaultList);
        return defaultList;
      }
    } catch (e) {
      print('Error loading category list: $e');
      return CategoryList.getDefault();
    }
  }

  // Helper method to get bank mapping contents for debugging
  Future<String?> getBankMappingContents(String bankName) async {
    try {
      // Try primary location first
      final file = await getBankMappingFile(bankName);
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          return content;
        } catch (e) {
          print('Error reading bank mapping content: $e');
        }
      }
      
      // Try alternate paths
      final jsonString = await _tryReadFromAlternatePaths(bankName);
      if (jsonString.isNotEmpty) {
        return jsonString;
      }
      
      return null;
    } catch (e) {
      print('Error getting bank mapping contents: $e');
      return null;
    }
  }
  
  // Debug - Export all bank mapping files to Downloads directory
  Future<Map<String, String>> exportBankMappingsToDownloads() async {
    Map<String, String> results = {};
    try {
      // Get list of bank names
      final bankNames = await listSavedBankNames();
      
      // Create downloads directory path
      final downloadsDir = Directory('/storage/emulated/0/Download/PennyPilot');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Export each bank mapping
      for (final bankName in bankNames) {
        try {
          // Get the mapping content
          final content = await getBankMappingContents(bankName);
          if (content != null) {
            // Create export file
            final sanitizedName = bankName.replaceAll(RegExp(r'[^\w\.-]+'), '_');
            final exportFile = File('${downloadsDir.path}/${sanitizedName}_export.json');
            await exportFile.writeAsString(content);
            results[bankName] = exportFile.path;
          }
        } catch (e) {
          print('Error exporting $bankName: $e');
          results[bankName] = "Error: $e";
        }
      }
      
      return results;
    } catch (e) {
      print('Error exporting bank mappings: $e');
      return {'error': e.toString()};
    }
  }

  // Debug - Log all bank mapping files to console for IDE inspection
  Future<void> debugLogAllBankMappings() async {
    try {
      // Print base directory information
      if (_baseDirectory != null) {
        print('DEBUG: Base directory: ${_baseDirectory!.path}');
        print('DEBUG: Base directory exists: ${await _baseDirectory!.exists()}');
      } else {
        print('DEBUG: Base directory is null!');
      }
      
      // Print banks directory information
      try {
        final banksDir = await _banksDirectory;
        print('DEBUG: Banks directory: ${banksDir.path}');
        print('DEBUG: Banks directory exists: ${await banksDir.exists()}');
        
        // List files in the banks directory
        if (await banksDir.exists()) {
          final files = await banksDir.list().toList();
          print('DEBUG: Files in banks directory (${files.length}):');
          for (var file in files) {
            print('DEBUG:   - ${file.path} (${file is File ? "FILE" : "DIR"})');
          }
        }
      } catch (e) {
        print('DEBUG: Error accessing banks directory: $e');
      }
      
      final bankNames = await listSavedBankNames();
      
      if (bankNames.isEmpty) {
        print('DEBUG: No bank mappings found in listSavedBankNames()');
        return;
      }
      
      print('DEBUG: Found ${bankNames.length} bank mappings: ${bankNames.join(', ')}');
      
      for (final bankName in bankNames) {
        try {
          final file = await getBankMappingFile(bankName);
          print('DEBUG: Bank: $bankName, File path: ${file.path}');
          print('DEBUG: File exists: ${await file.exists()}');
          
          if (await file.exists()) {
            final contents = await file.readAsString();
            print('DEBUG: Contents of $bankName mapping:');
            print('----------------------');
            print(contents);
            print('----------------------');
          } else {
            print('DEBUG: $bankName mapping file does not exist!');
          }
        } catch (e) {
          print('DEBUG: Error reading $bankName mapping: $e');
        }
      }
    } catch (e) {
      print('DEBUG: Error in debugLogAllBankMappings: $e');
    }
  }

  // --- CSV Processing Methods ---
  
  /// Parse a CSV file and return the rows
  Future<List<List<dynamic>>> parseCSV(File file) async {
    try {
      // Use latin1 encoding to match the processCSVFile method
      final String csvString = await file.readAsString(encoding: latin1);
      
      // Initial parse with comma as delimiter (will be refined later)
      final List<List<dynamic>> rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(csvString);
      
      return rows;
    } catch (e) {
      print('Error parsing CSV file: $e');
      return [];
    }
  }
  
  /// Process a CSV file using a bank mapping and return the transactions
  Future<List<Transaction>> processCSVFile(
    File file,
    String? bankName,
    BankMapping? mapping,
  ) async {
    print('Processing CSV file: ${file.path}');
    try {
      if (bankName == null || mapping == null) {
        // Log the issue but continue with default values
        print('Warning: Bank name or mapping is null. Using defaults.');
        bankName = bankName ?? "Unknown Bank";
        
        if (mapping == null) {
          // Create a simple default mapping with some assumptions
          // This may not work for all CSVs but gives a fallback
          mapping = BankMapping(
            bankName: bankName,
            headerRowIndex: 0,
            dateColumn: "Date",
            descriptionColumn: "Description",
            amountColumn: "Amount",
            delimiter: ",",
            dateFormatType: DateFormatType.iso,
            amountMappingType: AmountMappingType.single
          );
          
          print('Created default mapping for ${bankName}');
        }
      }
      
      // Read the file
      final String csvString = await file.readAsString(encoding: latin1);
      
      // Parse the CSV with correct delimiter
      final String delimiter = mapping.delimiter ?? ',';
      print('Using delimiter: "$delimiter"');
      
      final List<List<dynamic>> rows = CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
        fieldDelimiter: delimiter,
      ).convert(csvString);
      
      if (rows.isEmpty) {
        print('No rows found in CSV file');
        return [];
      }
      
      // Get header row (ensure index is valid)
      final headerRowIndex = mapping.headerRowIndex < rows.length ? mapping.headerRowIndex : 0;
      final headerRow = rows[headerRowIndex];
      
      print('Using header row: $headerRowIndex');
      print('Header columns: ${headerRow.join(", ")}');
      
      // Create a map of column names to indices
      Map<String, int> columnMap = {};
      for (int i = 0; i < headerRow.length; i++) {
        // Store both the original column name and a normalized version (lowercase, trimmed)
        final String colName = headerRow[i].toString();
        columnMap[colName] = i;
        // Also add normalized version to improve matching
        columnMap[colName.toLowerCase().trim()] = i;
      }
      
      // Log the column mapping
      print('Column mappings:');
      print('Date column: ${mapping.dateColumn}');
      print('Description column: ${mapping.descriptionColumn}');
      print('Amount type: ${mapping.amountMappingType}');
      if (mapping.amountMappingType == AmountMappingType.single) {
        print('Amount column: ${mapping.amountColumn}');
      } else {
        print('Debit column: ${mapping.debitColumn}');
        print('Credit column: ${mapping.creditColumn}');
      }
      print('Available columns in CSV: ${columnMap.keys.toList()}');
      
      // Extract transactions based on the mapping
      List<Transaction> transactions = [];
      
      // Process each data row (skip header)
      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final dataRow = rows[i];
        
        // Skip rows that don't have enough columns
        if (dataRow.length < headerRow.length) {
          print('Skipping row $i: Not enough columns');
          continue;
        }
        
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
        
        // Helper function to find the value for a column regardless of case
        String? getColumnValue(String? columnName) {
          if (columnName == null) return null;
          
          // Try exact match
          if (rowData.containsKey(columnName)) {
            return rowData[columnName]?.toString();
          }
          
          // Try lowercase match
          final lowerColumnName = columnName.toLowerCase().trim();
          if (rowData.containsKey(lowerColumnName)) {
            return rowData[lowerColumnName]?.toString();
          }
          
          // Try to find a close match (contains)
          for (final key in rowData.keys) {
            if (key.toLowerCase().contains(lowerColumnName) || 
                lowerColumnName.contains(key.toLowerCase())) {
              return rowData[key]?.toString();
            }
          }
          
          return null;
        }
        
        // Map date column
        final dateValue = getColumnValue(mapping.dateColumn);
        if (dateValue != null) {
          transactionData['date'] = dateValue;
        } else {
          print('Warning: Date column "${mapping.dateColumn}" not found in row data for row $i');
        }
        
        // Map description column
        final descValue = getColumnValue(mapping.descriptionColumn);
        if (descValue != null) {
          transactionData['description'] = descValue;
        } else {
          print('Warning: Description column "${mapping.descriptionColumn}" not found in row data for row $i');
        }
        
        // Map amount columns based on mapping type
        if (mapping.amountMappingType == AmountMappingType.single) {
          // Single amount column
          final amountValue = getColumnValue(mapping.amountColumn);
          if (amountValue != null) {
            transactionData['amount'] = amountValue;
          } else {
            print('Warning: Amount column "${mapping.amountColumn}" not found in row data for row $i');
          }
        } else {
          // Separate debit/credit columns
          final debitValue = getColumnValue(mapping.debitColumn);
          if (debitValue != null) {
            transactionData['debit'] = debitValue;
          } else {
            print('Warning: Debit column "${mapping.debitColumn}" not found in row data for row $i');
          }
          
          final creditValue = getColumnValue(mapping.creditColumn);
          if (creditValue != null) {
            transactionData['credit'] = creditValue;
          } else {
            print('Warning: Credit column "${mapping.creditColumn}" not found in row data for row $i');
          }
        }
        
        // Create transaction
        try {
          final transaction = Transaction.fromCsvRow(
            transactionData, 
            bankName,
            dateFormatType: mapping.dateFormatType ?? DateFormatType.iso
          );
          transactions.add(transaction);
        } catch (e) {
          print('Error creating transaction from row $i: $e');
          // Skip this row and continue
        }
      }
      
      print('Parsed ${transactions.length} transactions from CSV');
      return transactions;
    } catch (e) {
      print('Error processing CSV file: $e');
      return [];
    }
  }
  
  /// Detect delimiter from a header line
  String _detectDelimiter(String headerLine) {
    // Count occurrences of common delimiters
    final commaCount = ','.allMatches(headerLine).length;
    final semicolonCount = ';'.allMatches(headerLine).length;
    final tabCount = '\t'.allMatches(headerLine).length;
    
    // Return the most common delimiter
    if (semicolonCount > commaCount && semicolonCount > tabCount) {
      return ';';
    } else if (tabCount > commaCount && tabCount > semicolonCount) {
      return '\t';
    } else {
      return ','; // Default to comma
    }
  }

  // --- Current Month Data Methods ---
  
  /// Get the current month data file
  Future<File> getCurrentMonthFile() async {
    final dataDir = await _dataDirectory;
    return File('${dataDir.path}/current_month.json');
  }
  
  /// Initialize or get current month data file
  Future<File> initializeCurrentMonthFile() async {
    final file = await getCurrentMonthFile();
    
    // If file doesn't exist, create it with empty structure
    if (!await file.exists()) {
      final now = DateTime.now();
      final emptyData = {
        'month': now.month,
        'year': now.year,
        'transactions': [],
        'lastUpdated': now.toIso8601String(),
      };
      
      // Use safe write for initialization
      await _integrityService.safeWriteJson(file, emptyData);
    }
    
    return file;
  }
  
  /// Save transactions to current month file
  Future<bool> saveTransactionsToCurrentMonth(List<Transaction> transactions) async {
    try {
      // Initialize the file if it doesn't exist
      final file = await initializeCurrentMonthFile();
      
      // Read existing data safely
      final data = await _integrityService.safeReadJson(file);
      
      if (data == null) {
        print('Error reading current month data');
        return false;
      }
      
      // Get existing transactions
      List<dynamic> existingTransactions = data['transactions'] as List? ?? [];
      
      // Add new transactions
      final allTransactions = [
        ...existingTransactions,
        ...transactions.map((t) => t.toJson()),
      ];
      
      // Update the data
      final now = DateTime.now();
      final updatedData = {
        'month': now.month,
        'year': now.year,
        'transactions': allTransactions,
        'lastUpdated': now.toIso8601String(),
      };
      
      // Write back to file safely
      return await _integrityService.safeWriteJson(file, updatedData);
    } catch (e) {
      print('Error saving transactions to current month: $e');
      return false;
    }
  }
  
  /// Get transactions from current month file
  Future<List<Transaction>> getCurrentMonthTransactions() async {
    try {
      final file = await getCurrentMonthFile();
      
      if (!await file.exists()) {
        return [];
      }
      
      // Read safely with validation
      final data = await _integrityService.safeReadJson(file);
      
      if (data == null) {
        print('Error reading current month data');
        return [];
      }
      
      // Extract transactions
      final transactionsList = data['transactions'] as List? ?? [];
      
      return transactionsList
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting current month transactions: $e');
      return [];
    }
  }

  /// Write JSON data to a file with error handling
  Future<bool> _writeJson(File file, Map<String, dynamic> jsonData) async {
    try {
      final jsonString = jsonEncode(jsonData);
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      print('Error writing JSON to ${file.path}: $e');
      return false;
    }
  }

  Future<bool> deleteBankMapping(String bankName) async {
    try {
      bool deleted = false;
      
      // Try primary directory first
      try {
        final file = await getBankMappingFile(bankName);
        if (await file.exists()) {
          await file.delete();
          print('Deleted bank mapping from: ${file.path}');
          deleted = true;
        }
      } catch (e) {
        print('Error deleting bank mapping from primary location: $e');
      }
      
      // Also check known alternate paths
      final sanitizedName = bankName.replaceAll(RegExp(r'[^\w\.-]+'), '_');
      final List<String> alternatePaths = [
        '/data/data/com.example.pennypilot/cache/banks',
        '/data/user/0/com.example.pennypilot/cache/banks'
      ];
      
      for (final dirPath in alternatePaths) {
        try {
          final alternateFile = File('${dirPath}/$sanitizedName.json');
          if (await alternateFile.exists()) {
            await alternateFile.delete();
            print('Deleted bank mapping from alternate path: ${alternateFile.path}');
            deleted = true;
          }
        } catch (e) {
          print('Error deleting bank mapping from $dirPath: $e');
        }
      }
      
      return deleted;
    } catch (e) {
      print('Error deleting bank mapping for $bankName: $e');
      return false;
    }
  }

  // Validate all bank mappings, return list of issues
  Future<Map<String, String>> validateAllBankMappings() async {
    Map<String, String> issues = {};
    
    try {
      // Get list of all bank names from all possible directories
      final bankNames = await listSavedBankNames();
      
      if (bankNames.isEmpty) {
        return {'general': 'No bank mappings found'};
      }
      
      // Check each bank mapping
      for (final bankName in bankNames) {
        try {
          // Try to load the mapping
          final mapping = await loadBankMapping(bankName);
          
          if (mapping == null) {
            issues[bankName] = 'Could not load bank mapping';
            continue;
          }
          
          // Check if mapping has necessary fields
          if (mapping.dateColumn == null) {
            issues[bankName] = 'Missing date column';
          } else if (mapping.descriptionColumn == null) {
            issues[bankName] = 'Missing description column';
          } else if (mapping.amountMappingType == AmountMappingType.single && mapping.amountColumn == null) {
            issues[bankName] = 'Missing amount column';
          } else if (mapping.amountMappingType == AmountMappingType.separate && 
                    (mapping.debitColumn == null || mapping.creditColumn == null)) {
            issues[bankName] = 'Missing debit or credit column';
          }
        } catch (e) {
          issues[bankName] = 'Error validating mapping: $e';
        }
      }
      
      return issues;
    } catch (e) {
      return {'general': 'Error validating bank mappings: $e'};
    }
  }
} 