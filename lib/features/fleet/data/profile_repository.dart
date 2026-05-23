import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bookings/data/booking_repository.dart';
import '../domain/profile.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Fetch all profiles for user management
  Future<List<Profile>> fetchProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      final list = response as List;
      return list.map((json) => Profile.fromJson(json)).toList();
    } catch (_) {
      // Mock data fallback
      return [
        Profile(
          id: 'eb3d0851-c518-4034-b806-c88411160e24',
          email: 'shaban.ejj@gmail.com',
          role: 'Admin',
        ),
        Profile(
          id: 'mock-u2',
          email: 'partner.test@spacerent.com',
          role: 'Partner',
        ),
        Profile(
          id: 'mock-u3',
          email: 'customer.test@gmail.com',
          role: 'Customer',
        ),
      ];
    }
  }

  /// Update a profile's role
  Future<void> updateProfileRole(String id, String role) async {
    try {
      await _supabase.from('profiles').update({'role': role}).eq('id', id);
    } catch (e) {
      if (e.toString().contains('placeholder')) return;
      rethrow;
    }
  }

  /// Create/Add a new profile
  Future<Profile> addProfile(Profile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .insert(profile.toJson())
          .select()
          .single();
      return Profile.fromJson(response);
    } catch (e) {
      if (e.toString().contains('placeholder')) return profile;
      rethrow;
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String id) async {
    try {
      await _supabase.from('profiles').delete().eq('id', id);
    } catch (e) {
      if (e.toString().contains('placeholder')) return;
      rethrow;
    }
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
}

@riverpod
Future<List<Profile>> profilesList(ProfilesListRef ref) {
  return ref.watch(profileRepositoryProvider).fetchProfiles();
}
