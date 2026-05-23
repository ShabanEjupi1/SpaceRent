import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../data/partner_repository.dart';
import '../../../bookings/data/booking_repository.dart';

class SubscriptionStatusBanner extends HookConsumerWidget {
  const SubscriptionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(currentPartnerProvider);
    if (partner == null) return const SizedBox.shrink();

    final partnerDetailsAsync = ref.watch(partnerDetailsProvider(partner.id));
    final isProcessing = useState(false);
    final paypalOrderId = useState<String?>(null);
    final errorMessage = useState<String?>(null);

    final supabase = ref.watch(supabaseClientProvider);

    // Call PayPal Edge Function to create order for subscription
    Future<void> initiateSubscription() async {
      isProcessing.value = true;
      errorMessage.value = null;

      try {
        final response = await supabase.functions.invoke(
          'paypal',
          body: {
            'action': 'create-order',
            'amount': 29.00, // Monthly Subscription Price
          },
        );

        if (response.status != 200) {
          throw Exception(response.data['error'] ?? 'Failed to initiate subscription.');
        }

        final data = response.data as Map<String, dynamic>;
        final orderId = data['orderId'] as String;
        final approvalUrl = data['approvalUrl'] as String;

        paypalOrderId.value = orderId;

        // Launch PayPal checkout
        final uri = Uri.parse(approvalUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open PayPal subscription checkout page.');
        }
      } catch (e) {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      } finally {
        isProcessing.value = false;
      }
    }

    // Call PayPal Edge Function to capture subscription fee
    Future<void> captureSubscription() async {
      if (paypalOrderId.value == null) return;
      isProcessing.value = true;
      errorMessage.value = null;

      try {
        final response = await supabase.functions.invoke(
          'paypal',
          body: {
            'action': 'capture-subscription',
            'orderId': paypalOrderId.value,
            'partnerId': partner.id,
            'amount': 29.00,
          },
        );

        if (response.status != 200) {
          throw Exception(response.data['error'] ?? 'Failed to capture subscription payment.');
        }

        // Refresh partner details provider to reflect active subscription
        ref.invalidate(partnerDetailsProvider(partner.id));
        paypalOrderId.value = null;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF00CEC9),
              content: Text('Subscription successfully activated!'),
            ),
          );
        }
      } catch (e) {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      } finally {
        isProcessing.value = false;
      }
    }

    return partnerDetailsAsync.when(
      data: (details) {
        if (details == null) return const SizedBox.shrink();

        final now = DateTime.now();
        final isActive = details.subscriptionStatus == 'Active' &&
            details.subscriptionExpiresAt != null &&
            details.subscriptionExpiresAt!.isAfter(now);

        final expStr = details.subscriptionExpiresAt != null
            ? DateFormat('dd MMM yyyy').format(details.subscriptionExpiresAt!)
            : 'N/A';

        if (isActive) {
          // Sleek Active Status Banner
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00CEC9).withOpacity(0.15), const Color(0xFF6C5CE7).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00CEC9).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF00CEC9), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SpaceRent Partner Plan is Active',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your vehicles are fully visible and open for user bookings. Next renewal: $expStr.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CEC9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        // Inactive / Call to Action Banner
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6C5CE7).withOpacity(0.15), const Color(0xFFFF6B6B).withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFF6C5CE7), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SpaceRent Partner Subscription Required',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Activate your monthly partner plan (€29.00/month) to list new vehicles and keep your existing fleet visible.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (errorMessage.value != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                  ),
                  child: Text(errorMessage.value!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (paypalOrderId.value == null) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: isProcessing.value ? null : initiateSubscription,
                      icon: isProcessing.value
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.subscriptions_outlined, size: 18),
                      label: const Text('Subscribe (€29/mo)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    const Text('Checkout page opened...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CEC9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: isProcessing.value ? null : captureSubscription,
                      child: isProcessing.value
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Payment Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: isProcessing.value
                          ? null
                          : () {
                              paypalOrderId.value = null;
                              errorMessage.value = null;
                            },
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
