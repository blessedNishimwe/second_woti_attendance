import '../models/user_model.dart';
import '../exceptions/app_exceptions.dart';
import '../services/cache_service.dart';

/// Optimized user repository with caching and performance improvements
class OptimizedUserRepository {
  final CacheService _cacheService = CacheService();
  
  /// Get current user with caching
  Future<UserModel?> getCurrentUser() async {
    // Try cache first
    final cachedUser = _cacheService.getCache<Map<String, dynamic>>(CacheKeys.userProfile);
    if (cachedUser != null) {
      return UserModel.fromJson(cachedUser);
    }

    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .single();
      
      final user = UserModel.fromJson(response);
      
      // Cache the user data
      await _cacheService.setCache(
        CacheKeys.userProfile, 
        response,
        ttl: const Duration(hours: 2),
      );
      
      return user;
    } catch (e) {
      if (e.toString().contains('PGRST116')) {
        return null;
      }
      throw DatabaseException('Failed to get current user: ${e.toString()}');
    }
  }

  /// Update user with cache invalidation
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .update(user.toJson())
          .eq('id', user.id)
          .select()
          .single();
      
      final updatedUser = UserModel.fromJson(response);
      
      // Update cache
      await _cacheService.setCache(
        CacheKeys.userProfile, 
        response,
        ttl: const Duration(hours: 2),
      );
      
      return updatedUser;
    } catch (e) {
      throw DatabaseException('Failed to update user: ${e.toString()}');
    }
  }

  /// Delete user with cache invalidation
  Future<void> deleteUser(String userId) async {
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .delete()
          .eq('id', userId);
      
      // Remove from cache
      await _cacheService.removeCache(CacheKeys.userProfile);
    } catch (e) {
      throw DatabaseException('Failed to delete user: ${e.toString()}');
    }
  }

  /// Get users by facility with pagination
  Future<List<UserModel>> getUsersByFacility(
    String facilityId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('facility_id', facilityId)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get users by facility: ${e.toString()}');
    }
  }

  /// Clear user cache
  Future<void> clearUserCache() async {
    await _cacheService.removeCache(CacheKeys.userProfile);
  }
}
