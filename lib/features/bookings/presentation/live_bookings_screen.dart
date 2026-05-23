import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/admin_booking_repository.dart';
import '../../search/data/vehicle_repository.dart';

class LiveBookingsScreen extends ConsumerWidget {
  const LiveBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveBookingsAsync = ref.watch(liveBookingsListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider());

    // Map vehicles for easy lookup
    final vehicleMap = vehiclesAsync.maybeWhen(
      data: (list) => {for (var v in list) v.id: '${v.brand} ${v.model}'},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Live Booking Stream',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.wifi_tethering, color: Color(0xFF00CEC9), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Realtime Stream Connections Active',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: liveBookingsAsync.when(
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return const Center(
                        child: Text(
                          'No rental bookings logged in system yet.',
                          style: TextStyle(color: Colors.white30),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final vehicleName = vehicleMap[booking.vehicleId] ?? 'Premium Vehicle';

                        final startStr = DateFormat('dd MMM yyyy').format(booking.startDate);
                        final endStr = DateFormat('dd MMM yyyy').format(booking.endDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left: Vehicle details & Date Range
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicleName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white54),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$startStr - $endStr',
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Middle: Total price
                              Text(
                                '€${booking.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF00CEC9), // Neo Teal
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),

                              // Right: Booking Status & Action Controls
                              Row(
                                children: [
                                  _StatusChip(status: booking.status),
                                  const SizedBox(width: 16),
                                  if (booking.status == 'Pending') ...[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.withOpacity(0.2),
                                        foregroundColor: Colors.greenAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(adminBookingRepositoryProvider)
                                            .updateBookingStatus(booking.id, 'Confirmed');
                                      },
                                      child: const Text('Confirm'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(adminBookingRepositoryProvider)
                                            .updateBookingStatus(booking.id, 'Cancelled');
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      if (status == 'Confirmed') return Colors.green;
      if (status == 'Cancelled') return Colors.redAccent;
      return Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getStatusColor().withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
