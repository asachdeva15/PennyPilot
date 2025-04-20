import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/bank_mapping.dart'; // Import the model
import '../models/transaction.dart';
import '../models/category_mapping.dart';

class FileService {
  // Store our base directory once we've found a working one
  Directory? _baseDirectory;
  
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
        // Test if we can write to it
        final testFile = File('${banksDir.path}/test.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        
        return banksDir;
      } catch (e) {
        print('Error creating or writing to banks directory: $e');
        
        // Try alternate location - app's cache directory
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
          
          print('Using alternate banks directory: ${alternateBanksDir.path}');
          return alternateBanksDir;
        } catch (e2) {
          print('Error creating alternate banks directory: $e2');
          throw Exception('Cannot find a writable directory for bank data');
        }
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

  Future<void> saveBankMapping(BankMapping mapping) async {
    try {
      final file = await getBankMappingFile(mapping.bankName);
      final jsonString = jsonEncode(mapping.toJson()); // Use generated toJson
      await file.writeAsString(jsonString);
      print('Mapping saved to: ${file.path}');
    } catch (e) {
      print('Error saving bank mapping: $e');
      // Rethrow or handle as needed
      rethrow;
    }
  }

  Future<BankMapping?> loadBankMapping(String bankName) async {
    try {
      final file = await getBankMappingFile(bankName);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        
        // Fix for compatibility with old DateFormatType enum format
        if (jsonMap.containsKey('dateFormatType') && jsonMap['dateFormatType'] != null) {
          // Convert old format (named with camelCase) to new format (lowercase)
          final oldFormat = jsonMap['dateFormatType'] as int;
          
          // Map the old enum index to the new enum index
          // Old enum: mmDdYyyy=1, ddMmYyyy=2, yyyyMmDd=3
          // New enum: mmddyyyy=1, ddmmyyyy=2, yyyymmdd=3
          // (indices remain the same but names changed)
          jsonMap['dateFormatType'] = oldFormat;
        }
        
        return BankMapping.fromJson(jsonMap);
      } else {
        print('Bank mapping file does not exist for $bankName');
        return null;
      }
    } catch (e) {
      print('Error loading bank mapping for $bankName: $e');
      return null;
    }
  }

  Future<List<String>> listSavedBankNames() async {
    try {
      // Try to get directory with additional error handling
      Directory? dir;
      try {
        dir = await _banksDirectory;
      } catch (e) {
        print('Error getting banks directory: $e');
        return []; // Return empty list on error
      }
      
      if (dir == null || !await dir.exists()) {
        print('Banks directory does not exist');
        return [];
      }
      
      final List<String> bankNames = [];
      List<FileSystemEntity> files;
      
      try {
        files = dir.listSync(); // List files synchronously after getting dir
      } catch (e) {
        print('Error listing files in banks directory: $e');
        return []; // Return empty list on error
      }

      for (var fileEntity in files) {
        if (fileEntity is File && fileEntity.path.endsWith('.json')) {
          // Try to load the mapping to get the original bank name
          try {
             final jsonString = await fileEntity.readAsString();
             final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
             
             // Try to fix compatibility issues before parsing
             if (jsonMap.containsKey('dateFormatType') && jsonMap['dateFormatType'] != null) {
               final oldFormat = jsonMap['dateFormatType'] as int;
               jsonMap['dateFormatType'] = oldFormat;
             }
             
             final mapping = BankMapping.fromJson(jsonMap);
             bankNames.add(mapping.bankName); // Only add if successfully parsed
          } catch (e) {
             print("Error reading bank mapping from ${fileEntity.path}: $e");
             // Don't add the bank if we can't parse its mapping
          }
        }
      }
      // Sort alphabetically, case-insensitive
      bankNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return bankNames;
    } catch (e) {
      print('Error listing saved bank names: $e');
      return []; // Return empty list on error
    }
  }

  // --- Category Mapping Files ---
  
  Future<File> getCategoryMappingFile(String keyword) async {
    // Sanitize keyword for filename
    final sanitizedName = keyword.replaceAll(RegExp(r'[^\w\.-]+'), '_');
    final dir = await _mappingsDirectory;
    return File('${dir.path}/$sanitizedName.json');
  }
  
  Future<void> saveCategoryMapping(CategoryMapping mapping) async {
    try {
      final file = await getCategoryMappingFile(mapping.keyword);
      final jsonString = jsonEncode(mapping.toJson());
      await file.writeAsString(jsonString);
      print('Category mapping saved to: ${file.path}');
    } catch (e) {
      print('Error saving category mapping: $e');
      rethrow;
    }
  }
  
  Future<CategoryMapping?> loadCategoryMapping(String keyword) async {
    try {
      final file = await getCategoryMappingFile(keyword);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return CategoryMapping.fromJson(jsonMap);
      } else {
        return null;
      }
    } catch (e) {
      print('Error loading category mapping for $keyword: $e');
      return null;
    }
  }
  
  Future<List<CategoryMapping>> loadAllCategoryMappings() async {
    try {
      final dir = await _mappingsDirectory;
      if (!await dir.exists()) {
        return [];
      }
      
      final List<CategoryMapping> mappings = [];
      final files = await dir.list().where((entity) => 
        entity is File && entity.path.endsWith('.json')
      ).toList();
      
      for (var file in files) {
        try {
          final jsonString = await (file as File).readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          mappings.add(CategoryMapping.fromJson(jsonMap));
        } catch (e) {
          print('Error loading category mapping from ${file.path}: $e');
        }
      }
      
      return mappings;
    } catch (e) {
      print('Error loading all category mappings: $e');
      return [];
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
      // Save individual transaction file
      final file = await getTransactionFile(transaction.id);
      final jsonString = jsonEncode(transaction.toJson());
      await file.writeAsString(jsonString);
      
      // Update transaction index
      final indexFile = await getTransactionIndexFile();
      Map<String, dynamic> index = {};
      
      if (await indexFile.exists()) {
        final indexString = await indexFile.readAsString();
        index = jsonDecode(indexString) as Map<String, dynamic>;
      }
      
      // Add/update transaction in index
      index[transaction.id] = {
        'date': transaction.date.toIso8601String(),
        'amount': transaction.amount,
        'description': transaction.description.substring(0, 
          transaction.description.length > 30 ? 30 : transaction.description.length),
        'category': transaction.category,
        'subcategory': transaction.subcategory,
      };
      
      await indexFile.writeAsString(jsonEncode(index));
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
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

  // Get the contents of a bank mapping file as a string
  Future<String?> getBankMappingContents(String bankName) async {
    try {
      final file = await getBankMappingFile(bankName);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return contents;
      } else {
        return null;
      }
    } catch (e) {
      print('Error reading bank mapping file: $e');
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
} 