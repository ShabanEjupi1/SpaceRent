import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/data/booking_repository.dart';

part 'admin_booking_repository.g.dart';

class AdminBookingRepository {
  final SupabaseClient _supabase;

  AdminBookingRepository(this._supabase);

  /// Subscribes to Supabase Realtime changes and streams a live list of bookings
  Stream<List<Booking>> watchLiveBookings() {
    try {
      return _supabase
          .from('bookings')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((rawList) => rawList.map((map) => Booking.fromJson(map)).toList());
    } catch (_) {
      // In development or if Supabase Realtime is offline/uninitialized,
      // fallback to polling or fake live stream to prevent hard crashes.
      return Stream.periodic(const Duration(seconds: 10)).asyncMap((_) async {
        final response = await _supabase
            .from('bookings')
            .select()
            .order('created_at', ascending: false);
        final list = response as List;
        return list.map((map) => Booking.fromJson(map)).toList();
      });
    }
  }

  /// Updates status of a booking (e.g. Pending -> Confirmed/Cancelled)
  Future<void> updateBookingStatus(String id, String status) async {
    await _supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', id);
  }
}

@riverpod
AdminBookingRepository adminBookingRepository(AdminBookingRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminBookingRepository(client);
}

@riverpod
Stream<List<Booking>> liveBookingsList(LiveBookingsListRef ref) {
  return ref.watch(adminBookingRepositoryProvider).watchLiveBookings();
}
