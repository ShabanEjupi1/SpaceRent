import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/data/booking_repository.dart';
import '../../notifications/email_service.dart';

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

  /// Updates status of a booking (e.g. Pending -> Confirmed/Cancelled) and triggers emails
  Future<void> updateBookingStatus(String id, String status) async {
    // 1. Perform database update
    await _supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', id);

    // 2. Query booking joined with vehicle and partner details
    try {
      final bookingData = await _supabase
          .from('bookings')
          .select('*, vehicles(*, locations(*), partners(*))')
          .eq('id', id)
          .single();

      final booking = Booking.fromJson(bookingData);
      final vehicleData = bookingData['vehicles'] as Map<String, dynamic>?;

      if (vehicleData != null) {
        final vehicleName = '${vehicleData['brand']} ${vehicleData['model']}';
        final partnerData = vehicleData['partners'] as Map<String, dynamic>?;
        
        final startStr = DateFormat('dd MMM yyyy').format(booking.startDate);
        final endStr = DateFormat('dd MMM yyyy').format(booking.endDate);
        
        final emailService = EmailService(_supabase);
        final bookingLang = booking.language ?? 'en';
        final paymentStatus = bookingData['payment_status'] as String? ?? 'Unpaid';

        // 1. Email to Customer (in localized language used for booking)
        if (booking.emailAddress != null && booking.emailAddress!.isNotEmpty) {
          await emailService.sendBookingStatusEmail(
            toEmail: booking.emailAddress!,
            recipientName: booking.fullName ?? 'Customer',
            vehicleName: vehicleName,
            customerName: booking.fullName ?? 'Guest',
            customerPhone: booking.phoneNumber ?? 'N/A',
            customerEmail: booking.emailAddress ?? 'N/A',
            startDate: startStr,
            endDate: endStr,
            totalPrice: booking.totalPrice.toStringAsFixed(0),
            newStatus: status,
            paymentStatus: paymentStatus,
            language: bookingLang,
          );
        }

        // 2. Email to Admin
        await emailService.sendBookingStatusEmail(
          toEmail: 'shaban.ejj@gmail.com',
          recipientName: 'Admin',
          vehicleName: vehicleName,
          customerName: booking.fullName ?? 'Guest',
          customerPhone: booking.phoneNumber ?? 'N/A',
          customerEmail: booking.emailAddress ?? 'N/A',
          startDate: startStr,
          endDate: endStr,
          totalPrice: booking.totalPrice.toStringAsFixed(0),
          newStatus: status,
          paymentStatus: paymentStatus,
          language: 'en',
        );

        // 3. Email to Partner (who owns the car)
        if (partnerData != null && partnerData['email'] != null) {
          await emailService.sendBookingStatusEmail(
            toEmail: partnerData['email'],
            recipientName: partnerData['contact_name'] ?? 'Partner',
            vehicleName: vehicleName,
            customerName: booking.fullName ?? 'Guest',
            customerPhone: booking.phoneNumber ?? 'N/A',
            customerEmail: booking.emailAddress ?? 'N/A',
            startDate: startStr,
            endDate: endStr,
            totalPrice: booking.totalPrice.toStringAsFixed(0),
            newStatus: status,
            paymentStatus: paymentStatus,
            language: 'en',
          );
        }
      }
    } catch (e) {
      // Avoid blocking operations if email dispatch fails
      // ignore: avoid_print
      print('[AdminBookingRepository] Failed to send booking update emails: $e');
    }
  }

  /// Deletes a booking
  Future<void> deleteBooking(String id) async {
    await _supabase
        .from('bookings')
        .delete()
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
