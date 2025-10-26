import '../models/user_model.dart';
import '../exceptions/app_exceptions.dart';

/// Abstract repository interface for user data operations
abstract class UserRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
  Future<List<UserModel>> getUsersByFacility(String facilityId);
}

/// Supabase implementation of UserRepository
class SupabaseUserRepository implements UserRepository {
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('PGRST116')) {
        // No user found
        return null;
      }
      throw DatabaseException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .update(user.toJson())
          .eq('id', user.id)
          .select()
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .delete()
          .eq('id', userId);
    } catch (e) {
      throw DatabaseException('Failed to delete user: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getUsersByFacility(String facilityId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('facility_id', facilityId);
      
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get users by facility: ${e.toString()}');
    }
  }
}
