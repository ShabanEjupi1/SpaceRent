import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../bookings/data/booking_repository.dart';
import '../../../bookings/domain/booking.dart';
import '../../domain/vehicle.dart';
import '../../../../core/l10n/locale_provider.dart';

class CheckoutOverlay extends HookConsumerWidget {
  final Vehicle vehicle;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final VoidCallback onSuccess;

  const CheckoutOverlay({
    super.key,
    required this.vehicle,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = useState(false);
    final paypalOrderId = useState<String?>(null);
    final paymentCaptured = useState(false);
    final errorMessage = useState<String?>(null);
    final paymentMethod = useState<String>('Online'); // 'Online' or 'Cash'

    final startStr = DateFormat('dd MMM yyyy').format(startDate);
    final endStr = DateFormat('dd MMM yyyy').format(endDate);
    final days = endDate.difference(startDate).inDays;

    final supabase = ref.watch(supabaseClientProvider);

    // Call database to submit Cash payment reservation
    Future<void> confirmCashBooking() async {
      isProcessing.value = true;
      errorMessage.value = null;

      try {
        final bookingId = const Uuid().v4();
        final booking = Booking(
          id: bookingId,
          vehicleId: vehicle.id,
          userId: const Uuid().v4(), // Guest ID
          startDate: startDate,
          endDate: endDate,
          totalPrice: totalPrice,
          status: 'Pending',
          fullName: fullName,
          phoneNumber: phoneNumber,
          emailAddress: emailAddress,
          language: ref.read(localeProvider),
          paymentStatus: 'Unpaid',
          paymentMethod: 'Cash',
        );

        await ref.read(bookingRepositoryProvider).submitBooking(booking);

        paymentCaptured.value = true;
        
        // Let user see success checkmark for a moment
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.of(context).pop(); // Close checkout overlay
            onSuccess();
          }
        });

      } catch (e) {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      } finally {
        isProcessing.value = false;
      }
    }

    // Call PayPal Edge Function to create order
    Future<void> initiatePayPalPayment() async {
      isProcessing.value = true;
      errorMessage.value = null;

      try {
        final response = await supabase.functions.invoke(
          'paypal',
          body: {
            'action': 'create-order',
            'amount': totalPrice,
          },
        );

        if (response.status != 200) {
          throw Exception(response.data['error'] ?? 'Failed to initiate PayPal checkout.');
        }

        final data = response.data as Map<String, dynamic>;
        final orderId = data['orderId'] as String;
        final approvalUrl = data['approvalUrl'] as String;

        paypalOrderId.value = orderId;

        // Launch PayPal approval URL
        final uri = Uri.parse(approvalUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open PayPal checkout page. Please disable pop-up blockers.');
        }
      } catch (e) {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      } finally {
        isProcessing.value = false;
      }
    }

    // Call PayPal Edge Function to capture order and save booking
    Future<void> verifyAndCapturePayment() async {
      if (paypalOrderId.value == null) return;
      
      isProcessing.value = true;
      errorMessage.value = null;

      try {
        // 1. First pre-create the booking in 'Pending' with 'Unpaid'
        final bookingId = const Uuid().v4();
        final booking = Booking(
          id: bookingId,
          vehicleId: vehicle.id,
          userId: const Uuid().v4(), // Guest ID
          startDate: startDate,
          endDate: endDate,
          totalPrice: totalPrice,
          status: 'Pending',
          fullName: fullName,
          phoneNumber: phoneNumber,
          emailAddress: emailAddress,
          language: ref.read(localeProvider),
          paymentStatus: 'Unpaid',
          paymentMethod: 'Online',
        );

        // Save booking client-side first so the backend capture can find it and update it
        await ref.read(bookingRepositoryProvider).submitBooking(booking);

        // 2. Call capture-order which updates database to 'Paid' and captures PayPal funds
        final response = await supabase.functions.invoke(
          'paypal',
          body: {
            'action': 'capture-order',
            'orderId': paypalOrderId.value,
            'bookingId': bookingId,
          },
        );

        if (response.status != 200) {
          throw Exception(response.data['error'] ?? 'PayPal payment capture failed.');
        }

        paymentCaptured.value = true;
        
        // Let user see success checkmark for a moment
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.of(context).pop(); // Close checkout overlay
            onSuccess();
          }
        });

      } catch (e) {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      } finally {
        isProcessing.value = false;
      }
    }

    return Dialog(
      backgroundColor: const Color(0xFF16162B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16162B), Color(0xFF0F0F1A)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/spacerent_logo.png', height: 40),
                  const SizedBox(width: 12),
                  const Text(
                    'Secure Checkout',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              if (!paymentCaptured.value) ...[
                // Payment Method Selector
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (paypalOrderId.value == null) {
                              paymentMethod.value = 'Online';
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: paymentMethod.value == 'Online' ? const Color(0xFF6C5CE7) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Pay Online',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (paypalOrderId.value == null) {
                              paymentMethod.value = 'Cash';
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: paymentMethod.value == 'Cash' ? const Color(0xFF00CEC9) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Pay in Hand',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Booking Summary
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white54),
                    const SizedBox(width: 6),
                    Text(
                      '$startStr — $endStr ($days days)',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pricing Detail Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daily Rate', style: TextStyle(color: Colors.white60, fontSize: 14)),
                          Text('€${vehicle.pricePerDay.toStringAsFixed(0)}/day', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration', style: TextStyle(color: Colors.white60, fontSize: 14)),
                          Text('$days days', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '€${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF00CEC9),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (errorMessage.value != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      errorMessage.value!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action States
                if (paymentMethod.value == 'Cash') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CEC9),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isProcessing.value ? null : confirmCashBooking,
                      icon: isProcessing.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Icon(Icons.handshake_outlined, size: 20),
                      label: const Text(
                        'Confirm Reservation (Pay in Hand)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ] else if (paypalOrderId.value == null) ...[
                  // Initial checkout launch
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC439), // PayPal Yellow
                        foregroundColor: const Color(0xFF003087), // PayPal Blue
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isProcessing.value ? null : initiatePayPalPayment,
                      icon: isProcessing.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Color(0xFF003087), strokeWidth: 2),
                            )
                          : const Icon(Icons.payment, size: 20),
                      label: const Text(
                        'Pay with PayPal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  // Awaiting approval and capture
                  const Text(
                    'Awaiting PayPal checkout...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please complete the transaction in the PayPal window that opened.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7), // Neo Violet
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isProcessing.value ? null : verifyAndCapturePayment,
                      child: isProcessing.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Payment Completed',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isProcessing.value
                        ? null
                        : () {
                            paypalOrderId.value = null;
                            errorMessage.value = null;
                          },
                    child: const Text('Back / Restart Payment', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ],
              ] else ...[
                // Payment Success Screen
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00CEC9), // Neo Teal
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Completed!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your booking is registered. An email notification has been sent.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
