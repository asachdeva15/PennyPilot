import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart'; // Import the home screen
import 'services/file_service.dart'; // Import FileService
import 'repositories/yearly_data_repository.dart'; // Import our new repository
import 'dart:async'; // For splash screen timing

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize file storage
  final fileService = FileService();
  bool storageInitialized = await fileService.initializeStorage();
  print('Storage initialization: ${storageInitialized ? 'SUCCESS' : 'FAILED'}');
  
  // Initialize yearly data repository
  final yearlyRepository = YearlyDataRepository();
  await yearlyRepository.initialize();
  
  // Debug: Log all bank mappings to console for IDE inspection
  await fileService.debugLogAllBankMappings();
  
  // Run the app
  runApp(const ProviderScope(child: PennyPilotApp()));
}

class PennyPilotApp extends StatelessWidget {
  const PennyPilotApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PennyPilot',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
           backgroundColor: Colors.grey[900],
           foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Use splash screen as initial screen
    );
  }
}

// Splash screen for app launch
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _migrationStarted = false;

  @override
  void initState() {
    super.initState();
    
    // Start data migration and navigate to home screen
    _initializeAndNavigate();
  }
  
  Future<void> _initializeAndNavigate() async {
    // Perform data migration in background if needed
    if (!_migrationStarted) {
      _migrationStarted = true;
      // Trigger migration in the background
      final yearlyRepository = YearlyDataRepository();
      await yearlyRepository.initialize();
      yearlyRepository.migrateFromLegacyStorage();
    }
    
    // Navigate to HomeScreen after 3 seconds regardless of migration status
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen())
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE68A00), // Background color #e68a00
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'LOGO.png', 
              width: 200,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
} 