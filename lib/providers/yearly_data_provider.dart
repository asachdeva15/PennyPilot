import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/yearly_data.dart';
import '../repositories/yearly_data_repository.dart';

/// Provider for the YearlyDataRepository
final yearlyDataRepositoryProvider = Provider<YearlyDataRepository>((ref) {
  return YearlyDataRepository();
});

/// Provider for current year data
final currentYearDataProvider = FutureProvider<YearlyData>((ref) async {
  final repository = ref.watch(yearlyDataRepositoryProvider);
  await repository.initialize();
  return repository.getCurrentYearData();
});

/// Provider for a specific year's data
final yearDataProvider = FutureProvider.family<YearlyData, int>((ref, year) async {
  final repository = ref.watch(yearlyDataRepositoryProvider);
  await repository.initialize();
  return repository.getYearlyData(year);
});

/// Provider for transactions in a specific month
final monthTransactionsProvider = FutureProvider.family<List<Transaction>, (int, int)>((ref, params) async {
  final (year, month) = params;
  final repository = ref.watch(yearlyDataRepositoryProvider);
  await repository.initialize();
  return repository.getTransactionsForMonth(year, month);
});

/// Provider for the migration status
final migrationStatusProvider = StateProvider<String?>((ref) => null);

/// Provider for triggering migration
final migrateDataProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(yearlyDataRepositoryProvider);
  await repository.initialize();
  
  ref.read(migrationStatusProvider.notifier).state = 'Migrating data...';
  
  try {
    final result = await repository.migrateFromLegacyStorage();
    ref.read(migrationStatusProvider.notifier).state = 
        result ? 'Migration complete' : 'Migration failed';
    return result;
  } catch (e) {
    ref.read(migrationStatusProvider.notifier).state = 'Migration error: $e';
    return false;
  }
}); 