import 'package:get_it/get_it.dart';
import '../repositories/user_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/optimized_user_repository.dart';
import '../repositories/optimized_attendance_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/optimized_auth_provider.dart';
import '../providers/optimized_attendance_provider.dart';
import '../services/cache_service.dart';
import '../services/location_service.dart';
import '../services/timer_service.dart';

/// Service locator for dependency injection
final GetIt serviceLocator = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Initialize cache service first
  await serviceLocator.registerSingletonAsync<CacheService>(
    () async {
      final cacheService = CacheService();
      await cacheService.initialize();
      return cacheService;
    },
  );

  // Register repositories
  serviceLocator.registerLazySingleton<UserRepository>(
    () => SupabaseUserRepository(),
  );
  
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => SupabaseAttendanceRepository(),
  );

  // Register optimized repositories
  serviceLocator.registerLazySingleton<OptimizedUserRepository>(
    () => OptimizedUserRepository(),
  );
  
  serviceLocator.registerLazySingleton<OptimizedAttendanceRepository>(
    () => OptimizedAttendanceRepository(),
  );

  // Register services
  serviceLocator.registerLazySingleton<LocationService>(
    () => LocationService(),
  );
  
  serviceLocator.registerLazySingleton<TimerService>(
    () => TimerService(),
  );

  // Register providers
  serviceLocator.registerFactory<AuthProvider>(
    () => AuthProvider(serviceLocator<UserRepository>()),
  );
  
  serviceLocator.registerFactory<AttendanceProvider>(
    () => AttendanceProvider(serviceLocator<AttendanceRepository>()),
  );

  // Register optimized providers
  serviceLocator.registerFactory<OptimizedAuthProvider>(
    () => OptimizedAuthProvider(serviceLocator<OptimizedUserRepository>()),
  );
  
  serviceLocator.registerFactory<OptimizedAttendanceProvider>(
    () => OptimizedAttendanceProvider(
      serviceLocator<OptimizedAttendanceRepository>(),
      serviceLocator<LocationService>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await serviceLocator.reset();
}
