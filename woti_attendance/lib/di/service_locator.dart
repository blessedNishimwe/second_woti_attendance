import 'package:get_it/get_it.dart';
import '../repositories/user_repository.dart';
import '../repositories/attendance_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';

/// Service locator for dependency injection
final GetIt serviceLocator = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Register repositories
  serviceLocator.registerLazySingleton<UserRepository>(
    () => SupabaseUserRepository(),
  );
  
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => SupabaseAttendanceRepository(),
  );

  // Register providers
  serviceLocator.registerFactory<AuthProvider>(
    () => AuthProvider(serviceLocator<UserRepository>()),
  );
  
  serviceLocator.registerFactory<AttendanceProvider>(
    () => AttendanceProvider(serviceLocator<AttendanceRepository>()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await serviceLocator.reset();
}
