import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/partner_repository.dart';
import '../../notifications/email_service.dart';
import '../../bookings/data/booking_repository.dart';

class PartnerApplicationsScreen extends ConsumerWidget {
  const PartnerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(partnerApplicationsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Partner Hub Applications',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review incoming business requests to join the SpaceRent Kosovo network',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: applicationsAsync.when(
                  data: (apps) {
                    if (apps.isEmpty) {
                      return const Center(
                        child: Text(
                          'No partner applications logged.',
                          style: TextStyle(color: Colors.white30),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          headingTextStyle: const TextStyle(
                            color: Color(0xFF00CEC9), // Neo Teal
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          columns: const [
                            DataColumn(label: Text('Company Name')),
                            DataColumn(label: Text('Contact Person')),
                            DataColumn(label: Text('Email Address')),
                            DataColumn(label: Text('Phone Number')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Invite Registration Link')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: apps.map((app) {
                            final statusColor = app.status == 'Approved'
                                ? Colors.green
                                : (app.status == 'Rejected' ? Colors.redAccent : Colors.amber);

                            final hasInviteToken = app.inviteToken != null && app.inviteToken!.isNotEmpty;
                            final inviteLink = () {
                              if (!hasInviteToken) return '';
                              if (kIsWeb) {
                                final uri = Uri.base;
                                final portStr = uri.hasPort ? ':${uri.port}' : '';
                                final hostStr = uri.host;
                                final schemeStr = uri.scheme;
                                if (hostStr.contains('github.io')) {
                                  return '$schemeStr://$hostStr/SpaceRent/partner/register?token=${app.inviteToken}';
                                }
                                return '$schemeStr://$hostStr$portStr/partner/register?token=${app.inviteToken}';
                              }
                              return 'https://shabanejupi1.github.io/SpaceRent/partner/register?token=${app.inviteToken}';
                            }();

                            return DataRow(
                              cells: [
                                DataCell(Text(app.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataCell(Text(app.contactName, style: const TextStyle(color: Colors.white70))),
                                DataCell(Text(app.email, style: const TextStyle(color: Colors.white70))),
                                DataCell(Text(app.phone, style: const TextStyle(color: Colors.white70))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      app.status,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  hasInviteToken
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Generated Link', style: TextStyle(color: Color(0xFF00CEC9), fontSize: 13, decoration: TextDecoration.underline)),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: inviteLink));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor: Color(0xFF00CEC9),
                                                    content: Text('Onboarding registration link copied to clipboard!'),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      : const Text('N/A', style: TextStyle(color: Colors.white30)),
                                ),
                                DataCell(
                                  app.status == 'Pending'
                                      ? ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6C5CE7),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () async {
                                            final inviteToken = const Uuid().v4();
                                            try {
                                              await ref
                                                  .read(partnerRepositoryProvider)
                                                  .approveApplication(app.id, inviteToken);

                                              // Send partner invite email
                                              final emailService = EmailService(ref.read(supabaseClientProvider));
                                              await emailService.sendPartnerInviteEmail(
                                                toEmail: app.email,
                                                companyName: app.companyName,
                                                contactName: app.contactName,
                                                inviteToken: inviteToken,
                                              );

                                              ref.invalidate(partnerApplicationsListProvider);

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: const Color(0xFF00CEC9),
                                                    content: Text('Approved! Invite email sent to ${app.email}'),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: Colors.redAccent,
                                                    content: Text('Error approving partner: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Approve'),
                                        )
                                      : const Icon(Icons.check, color: Colors.white30, size: 16),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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
