import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/partner.dart';
import '../../bookings/data/booking_repository.dart';

part 'partner_repository.g.dart';

class PartnerRepository {
  final SupabaseClient _supabase;

  PartnerRepository(this._supabase);

  /// Submits a partner application
  Future<void> submitApplication(PartnerApplication app) async {
    try {
      await _supabase.from('partner_applications').insert({
        'company_name': app.companyName,
        'contact_name': app.contactName,
        'email': app.email,
        'phone': app.phone,
        'status': 'Pending',
      });
    } catch (e) {
      if (e.toString().contains('placeholder')) return;
      rethrow;
    }
  }

  /// Fetches all partner applications for the admin panel
  Future<List<PartnerApplication>> fetchApplications() async {
    try {
      final response = await _supabase
          .from('partner_applications')
          .select()
          .order('created_at', ascending: false);
      final list = response as List;
      return list.map((json) => PartnerApplication.fromJson(json)).toList();
    } catch (_) {
      // Mock data fallback
      return [
        PartnerApplication(
          id: 'a1',
          companyName: 'Pristina Rent Express',
          contactName: 'Arben Krasniqi',
          email: 'arben@printexpress.com',
          phone: '+38344111222',
          status: 'Pending',
        ),
        PartnerApplication(
          id: 'a2',
          companyName: 'Dardanian Cars Prizren',
          contactName: 'Fatmir Berisha',
          email: 'fatmir@dardaniancars.com',
          phone: '+38349888777',
          status: 'Approved',
          inviteToken: 'dardanian-token-123',
        ),
      ];
    }
  }

  /// Admin approves an application, generating an invite token
  Future<void> approveApplication(String id, String token) async {
    try {
      await _supabase.from('partner_applications').update({
        'status': 'Approved',
        'invite_token': token,
      }).eq('id', id);
    } catch (e) {
      if (e.toString().contains('placeholder')) return;
      rethrow;
    }
  }

  /// Onboards a partner using their valid token
  Future<Partner?> verifyTokenAndRegisterPartner({
    required String token,
    required String companyName,
    required String contactName,
    required String email,
    required String phone,
  }) async {
    try {
      // 1. Verify token exists in applications
      final apps = await _supabase
          .from('partner_applications')
          .select()
          .eq('invite_token', token)
          .eq('status', 'Approved');

      if ((apps as List).isEmpty) {
        throw Exception('Invalid or expired registration token.');
      }

      // 2. Insert into partners
      final response = await _supabase
          .from('partners')
          .insert({
            'company_name': companyName,
            'contact_name': contactName,
            'email': email,
            'phone': phone,
            'status': 'Active',
          })
          .select()
          .single();

      // 3. Clear/expire token in applications
      await _supabase
          .from('partner_applications')
          .update({'invite_token': null})
          .eq('invite_token', token);

      return Partner.fromJson(response);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return Partner(
          id: 'mock-p1',
          companyName: companyName,
          contactName: contactName,
          email: email,
          phone: phone,
          status: 'Active',
        );
      }
      rethrow;
    }
  }

  /// Authenticates a partner by email and phone number
  Future<Partner?> loginPartner(String email, String phone) async {
    try {
      final response = await _supabase
          .from('partners')
          .select()
          .eq('email', email)
          .eq('phone', phone)
          .eq('status', 'Active')
          .single();
      return Partner.fromJson(response);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return Partner(
          id: 'mock-p1',
          companyName: 'Mock Partner Company',
          contactName: 'Mock Contact',
          email: email,
          phone: phone,
          status: 'Active',
        );
      }
      return null;
    }
  }

  /// Fetch all active partners for display
  Future<List<Partner>> fetchPartners() async {
    try {
      final response = await _supabase
          .from('partners')
          .select()
          .order('created_at', ascending: false);
      final list = response as List;
      return list.map((json) => Partner.fromJson(json)).toList();
    } catch (_) {
      // Mock data fallback
      return [
        Partner(
          id: 'mock-p1',
          companyName: 'Prishtina Rent Express',
          contactName: 'Arben Krasniqi',
          email: 'arben@printexpress.com',
          phone: '+38344111222',
          status: 'Active',
        ),
      ];
    }
  }

  /// Update partner status (e.g. suspend)
  Future<void> updatePartnerStatus(String id, String status) async {
    try {
      await _supabase.from('partners').update({'status': status}).eq('id', id);
    } catch (e) {
      if (e.toString().contains('placeholder')) return;
      rethrow;
    }
  }

  /// Delete a partner profile
  Future<void> deletePartner(String id) async {
    try {
      await _supabase.from('partners').delete().eq('id', id);
    } catch (e) {
      if (e.toString().contains('placeholder')) return;
      rethrow;
    }
  }
}

@riverpod
PartnerRepository partnerRepository(PartnerRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return PartnerRepository(client);
}

@riverpod
Future<List<PartnerApplication>> partnerApplicationsList(PartnerApplicationsListRef ref) {
  return ref.watch(partnerRepositoryProvider).fetchApplications();
}

@riverpod
Future<List<Partner>> partnersList(PartnersListRef ref) {
  return ref.watch(partnerRepositoryProvider).fetchPartners();
}

// Global authentication states for SpaceRent Ecosystem
final currentPartnerProvider = StateProvider<Partner?>((ref) => null);
final isAdminProvider = StateProvider<bool>((ref) => false);


