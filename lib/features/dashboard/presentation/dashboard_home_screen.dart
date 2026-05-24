import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../bookings/data/admin_booking_repository.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/domain/booking.dart';
import '../../fleet/data/partner_repository.dart';
import '../../fleet/data/profile_repository.dart';
import '../../fleet/domain/partner.dart';
import '../../fleet/domain/profile.dart';
import '../../fleet/presentation/widgets/add_car_dialog.dart';
import '../../fleet/presentation/widgets/edit_car_dialog.dart';
import '../../notifications/email_service.dart';
import '../../search/data/vehicle_repository.dart';
import '../../search/domain/location.dart';
import '../../search/domain/vehicle.dart';

class DashboardHomeScreen extends HookConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listeners and states
    final partner = ref.watch(currentPartnerProvider);
    final isUserAdmin = partner == null; // If no partner is logged in, we must be Admin (passcode bypass)

    final liveBookingsAsync = ref.watch(liveBookingsListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider());
    final locationsAsync = ref.watch(locationsProvider);
    final partnersAsync = ref.watch(partnersListProvider);
    final applicationsAsync = ref.watch(partnerApplicationsListProvider);
    final profilesAsync = ref.watch(profilesListProvider);

    // 2. Mock Support Requests
    final supportRequests = useState<List<Map<String, String>>>([
      {
        'id': 't1',
        'partner': 'Dardanian Cars',
        'subject': 'GPS Sync Error on Golf 8',
        'status': 'Open',
        'date': '23 May 2026'
      },
      {
        'id': 't2',
        'partner': 'Pristina Rent Express',
        'subject': 'Payout Account Update',
        'status': 'Resolved',
        'date': '22 May 2026'
      },
    ]);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final headerContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('brand_name', ref),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00CEC9),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUserAdmin ? tr('admin_subtitle', ref) : tr('partner_subtitle', ref),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUserAdmin
                            ? tr('admin_overview', ref)
                            : '${tr('partner_overview', ref)} ${partner.companyName}',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  );

                  final actionButtonsRow = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const AddCarDialog(),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(tr('add_vehicle', ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.04),
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showProfileSettingsDialog(context, ref),
                        icon: const Icon(Icons.settings, size: 18, color: Color(0xFF00CEC9)),
                        label: const Text('My Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerContent,
                        const SizedBox(height: 16),
                        actionButtonsRow,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: headerContent),
                      const SizedBox(width: 16),
                      actionButtonsRow,
                    ],
                  );
                },
              ),
            ),
          ),

          // Statistics Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverToBoxAdapter(
              child: _buildStatsGrid(
                ref: ref,
                isUserAdmin: isUserAdmin,
                partner: partner,
                bookingsAsync: liveBookingsAsync,
                vehiclesAsync: vehiclesAsync,
                partnersAsync: partnersAsync,
                applicationsAsync: applicationsAsync,
              ),
            ),
          ),

          // Main Dashboard Sections split
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isUserAdmin) ...[
                  // 1. Partner Onboarding Applications (Comm-Links)
                  _buildApplicationsSection(context, ref, applicationsAsync),
                  const SizedBox(height: 24),

                  // 2. Active Partners list
                  _buildActivePartnersSection(context, ref, partnersAsync),
                  const SizedBox(height: 24),

                  // 3. Profile Change Requests
                  _buildProfileChangeRequestsSection(context, ref),
                  const SizedBox(height: 24),

                  // 4. Support Requests
                  _buildSupportRequestsSection(context, ref, supportRequests),
                  const SizedBox(height: 24),

                  // 4. Locations Hubs Management
                  _buildLocationsSection(context, ref, locationsAsync),
                  const SizedBox(height: 24),

                  // 5. User Roles Management
                  _buildUserRolesSection(context, ref, profilesAsync),
                  const SizedBox(height: 24),
                ],

                // 6. Fleet Management (CRUD)
                _buildFleetSection(context, ref, vehiclesAsync, locationsAsync, partner),
                const SizedBox(height: 24),

                // 7. Recent Bookings for my vehicles (CRUD)
                _buildRecentBookingsSection(context, ref, liveBookingsAsync, vehiclesAsync, partner),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Statistics Grid UI Builder ---
  Widget _buildStatsGrid({
    required WidgetRef ref,
    required bool isUserAdmin,
    required Partner? partner,
    required AsyncValue<List<Booking>> bookingsAsync,
    required AsyncValue<List<Vehicle>> vehiclesAsync,
    required AsyncValue<List<Partner>> partnersAsync,
    required AsyncValue<List<PartnerApplication>> applicationsAsync,
  }) {
    final bookings = bookingsAsync.value ?? [];
    final vehicles = vehiclesAsync.value ?? [];
    final partners = partnersAsync.value ?? [];
    final applications = applicationsAsync.value ?? [];

    // Filter metrics if partner logged in
    final displayVehicles = isUserAdmin ? vehicles : vehicles.where((v) => v.partnerId == partner?.id).toList();
    final displayVehiclesIds = displayVehicles.map((v) => v.id).toSet();
    final displayBookings = isUserAdmin ? bookings : bookings.where((b) => displayVehiclesIds.contains(b.vehicleId)).toList();

    final totalBookings = displayBookings.length;
    final totalFleet = displayVehicles.length;

    final pendingPartners = isUserAdmin ? applications.where((a) => a.status == 'Pending').length : 0;
    final activePartners = isUserAdmin ? partners.where((p) => p.status == 'Active').length : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        final width = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        final items = [
          _StatCard(
            title: tr('total_bookings', ref),
            value: '$totalBookings',
            icon: Icons.assignment_turned_in_outlined,
            color: const Color(0xFF6C5CE7),
            width: width,
          ),
          if (isUserAdmin) ...[
            _StatCard(
              title: tr('pending_partners', ref),
              value: '$pendingPartners',
              icon: Icons.handshake_outlined,
              color: Colors.amber,
              width: width,
            ),
            _StatCard(
              title: tr('active_partners_label', ref),
              value: '$activePartners',
              icon: Icons.people_outline,
              color: const Color(0xFF00CEC9),
              width: width,
            ),
          ],
          _StatCard(
            title: tr('total_fleet', ref),
            value: '$totalFleet',
            icon: Icons.directions_car_outlined,
            color: Colors.green,
            width: width,
          ),
        ];

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items,
        );
      },
    );
  }

  // --- 2. Partner Onboarding Applications ---
  Widget _buildApplicationsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PartnerApplication>> applicationsAsync,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return _SectionCard(
      title: tr('partner_comm_links', ref),
      icon: Icons.connect_without_contact,
      child: applicationsAsync.when(
        data: (apps) {
          final pending = apps.where((a) => a.status == 'Pending').toList();
          if (pending.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  tr('no_pending_apps', ref),
                  style: const TextStyle(color: Colors.white30, fontSize: 13),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pending.length,
            separatorBuilder: (c, i) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final app = pending[index];
              final approveButton = ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final inviteToken = const Uuid().v4();
                  try {
                    await ref.read(partnerRepositoryProvider).approveApplication(app.id, inviteToken);

                    // Send partner invite email
                    final emailService = EmailService(ref.read(supabaseClientProvider));
                    await emailService.sendPartnerInviteEmail(
                      toEmail: app.email,
                      companyName: app.companyName,
                      contactName: app.contactName,
                      inviteToken: inviteToken,
                    );

                    ref.invalidate(partnerApplicationsListProvider);
                    ref.invalidate(partnersListProvider);

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
              );

              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Contact: ${app.contactName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Phone: ${app.phone}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Email: ${app.email}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: approveButton,
                      ),
                    ],
                  ),
                );
              }

              return ListTile(
                title: Text(app.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Contact: ${app.contactName} • ${app.phone} • ${app.email}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: approveButton,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  // --- 2b. Profile Change Requests list ---
  Widget _buildProfileChangeRequestsSection(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(profileChangeRequestsListProvider);

    return _SectionCard(
      title: 'Profile Change Requests',
      icon: Icons.assignment_late_outlined,
      child: requestsAsync.when(
        data: (requests) {
          final pendingReqs = requests.where((r) => r.status == 'Pending').toList();
          if (pendingReqs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No pending profile change requests.', style: TextStyle(color: Colors.white30, fontSize: 13)),
              ),
            );
          }

          final partners = ref.watch(partnersListProvider).value ?? [];

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingReqs.length,
            separatorBuilder: (c, i) => Divider(color: Colors.white.withOpacity(0.04)),
            itemBuilder: (context, index) {
              final req = pendingReqs[index];
              final partnerObj = partners.firstWhere(
                (p) => p.id == req.partnerId,
                orElse: () => Partner(id: '', companyName: 'Unknown', contactName: '', email: '', phone: '', status: ''),
              );

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          partnerObj.companyName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy HH:mm').format(req.createdAt),
                          style: const TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Requested Updates:', style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    if (req.companyName != null && req.companyName != partnerObj.companyName)
                      Text('• Company Name: ${partnerObj.companyName} ➔ ${req.companyName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (req.contactName != null && req.contactName != partnerObj.contactName)
                      Text('• Contact Name: ${partnerObj.contactName} ➔ ${req.contactName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (req.email != null && req.email != partnerObj.email)
                      Text('• Email: ${partnerObj.email} ➔ ${req.email}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (req.phone != null && req.phone != partnerObj.phone)
                      Text('• Password: ${partnerObj.phone} ➔ ${req.phone}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          onPressed: () async {
                            try {
                              await ref.read(partnerRepositoryProvider).rejectProfileChangeRequest(req.id);
                              ref.invalidate(profileChangeRequestsListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Rejected.')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(partnerRepositoryProvider).approveProfileChangeRequest(
                                req.id,
                                req.partnerId,
                                companyName: req.companyName,
                                contactName: req.contactName,
                                email: req.email,
                                phone: req.phone,
                              );
                              ref.invalidate(partnersListProvider);
                              ref.invalidate(profileChangeRequestsListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  backgroundColor: Color(0xFF00CEC9),
                                  content: Text('Request Approved & Profile Updated!'),
                                ));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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
    );
  }

  Widget _buildActivePartnersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Partner>> partnersAsync,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return _SectionCard(
      title: tr('active_partners', ref),
      icon: Icons.handshake,
      child: partnersAsync.when(
        data: (partners) {
          if (partners.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(tr('no_active_partners', ref), style: const TextStyle(color: Colors.white30, fontSize: 13)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: partners.length,
            separatorBuilder: (c, i) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final p = partners[index];
              final isSuspended = p.status == 'Suspended';

              final statusWidget = Text(
                p.status,
                style: TextStyle(
                  color: isSuspended ? Colors.redAccent : const Color(0xFF00CEC9),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF00CEC9), size: 20),
                    onPressed: () => _showEditPartnerDialog(context, ref, p),
                  ),
                  IconButton(
                    icon: Icon(
                      isSuspended ? Icons.play_arrow : Icons.pause,
                      color: Colors.amberAccent,
                      size: 20,
                    ),
                    onPressed: () async {
                      try {
                        final newStatus = isSuspended ? 'Active' : 'Suspended';
                        await ref.read(partnerRepositoryProvider).updatePartnerStatus(p.id, newStatus);
                        ref.invalidate(partnersListProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      try {
                        await ref.read(partnerRepositoryProvider).deletePartner(p.id);
                        ref.invalidate(partnersListProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                        }
                      }
                    },
                  ),
                ],
              );

              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(p.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          statusWidget,
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Contact: ${p.contactName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Email: ${p.email}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Actions:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                          const SizedBox(width: 8),
                          actionButtons,
                        ],
                      ),
                    ],
                  ),
                );
              }

              return ListTile(
                title: Text(p.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Contact: ${p.contactName} • ${p.email}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    statusWidget,
                    const SizedBox(width: 16),
                    actionButtons,
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  // --- 4. Support Requests ---
  Widget _buildSupportRequestsSection(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<Map<String, String>>> supportRequests,
  ) {
    final list = supportRequests.value;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return _SectionCard(
      title: '${tr('support_requests', ref)} (${list.length})',
      icon: Icons.contact_support_outlined,
      child: list.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(tr('no_support_requests', ref), style: const TextStyle(color: Colors.white30, fontSize: 13)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (c, i) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final req = list[index];
                final isOpen = req['status'] == 'Open';

                final statusWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.redAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isOpen ? Colors.redAccent : Colors.green),
                  ),
                  child: Text(
                    req['status']!,
                    style: TextStyle(color: isOpen ? Colors.redAccent : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );

                final actionButtons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOpen)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                        onPressed: () {
                          final newList = List<Map<String, String>>.from(supportRequests.value);
                          newList[index] = Map<String, String>.from(newList[index]);
                          newList[index]['status'] = 'Resolved';
                          supportRequests.value = newList;
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () {
                        final newList = List<Map<String, String>>.from(supportRequests.value);
                        newList.removeAt(index);
                        supportRequests.value = newList;
                      },
                    ),
                  ],
                );

                if (isMobile) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(req['subject']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            statusWidget,
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('From: ${req['partner']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Date: ${req['date']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            actionButtons,
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return ListTile(
                  title: Text(req['subject']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('From: ${req['partner']} • Date: ${req['date']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      statusWidget,
                      const SizedBox(width: 8),
                      actionButtons,
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- 5. Locations Management ---
  Widget _buildLocationsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Location>> locationsAsync,
  ) {
    final lang = ref.watch(localeProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return _SectionCard(
      title: tr('locations_management', ref),
      icon: Icons.map_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline Add Form
          _LocationAddForm(ref: ref),
          const SizedBox(height: 12),

          // Locations List
          locationsAsync.when(
            data: (locs) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: locs.length,
                separatorBuilder: (c, i) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final loc = locs[index];
                  final displayName = loc.getLocalizedName(lang);

                  final deleteButton = IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      try {
                        await ref.read(vehicleRepositoryProvider).deleteLocation(loc.id);
                        ref.invalidate(locationsProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                        }
                      }
                    },
                  );

                  if (isMobile) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Code: ${loc.code}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          deleteButton,
                        ],
                      ),
                    );
                  }

                  return ListTile(
                    title: Text('$displayName (${loc.code})', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('Code: ${loc.code}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: deleteButton,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  // --- 6. User Roles Management ---
  Widget _buildUserRolesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Profile>> profilesAsync,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return _SectionCard(
      title: tr('user_management', ref),
      icon: Icons.person_outline,
      child: profilesAsync.when(
        data: (profiles) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: profiles.length,
            separatorBuilder: (c, i) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final profile = profiles[index];

              final roleDropdown = DropdownButton<String>(
                dropdownColor: const Color(0xFF16162B),
                underline: const SizedBox(),
                value: profile.role,
                style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 13),
                items: ['Customer', 'Partner', 'Admin'].map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (newRole) async {
                  if (newRole != null) {
                    try {
                      await ref.read(profileRepositoryProvider).updateProfileRole(profile.id, newRole);
                      ref.invalidate(profilesListProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                      }
                    }
                  }
                },
              );

              final editButton = IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF00CEC9), size: 18),
                onPressed: () => _showEditProfileDialog(context, ref, profile),
              );

              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('ID: ${profile.id}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: roleDropdown,
                          ),
                          editButton,
                        ],
                      ),
                    ],
                  ),
                );
              }

              return ListTile(
                title: Text(profile.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('ID: ${profile.id}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    roleDropdown,
                    const SizedBox(width: 8),
                    editButton,
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, Profile profile) {
    final emailController = TextEditingController(text: profile.email);
    final passcodeController = TextEditingController();
    final supabase = ref.read(supabaseClientProvider);
    bool isPrefilling = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isPrefilling) {
            isPrefilling = false;
            supabase.from('profiles').select('passcode').eq('id', profile.id).maybeSingle().then((res) {
              if (res != null && res['passcode'] != null) {
                if (context.mounted) {
                  setState(() {
                    passcodeController.text = res['passcode'] as String;
                  });
                }
              }
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF16162B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passcodeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Passcode / Password',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await supabase.from('profiles').update({
                      'email': emailController.text.trim(),
                      'passcode': passcodeController.text.trim(),
                    }).eq('id', profile.id);
                    
                    ref.invalidate(profilesListProvider);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Profile updated successfully!'),
                      ));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Error: $e'),
                      ));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 7. Fleet Management CRUD ---
  Widget _buildFleetSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Vehicle>> vehiclesAsync,
    AsyncValue<List<Location>> locationsAsync,
    Partner? partner,
  ) {
    final lang = ref.watch(localeProvider);
    final locationMap = locationsAsync.maybeWhen(
      data: (list) => {for (var loc in list) loc.id: loc.getLocalizedName(lang)},
      orElse: () => <String, String>{},
    );

    return _SectionCard(
      title: tr('fleet_management', ref),
      icon: Icons.directions_car_outlined,
      child: vehiclesAsync.when(
        data: (vehicles) {
          final displayVehicles = partner == null
              ? vehicles
              : vehicles.where((v) => v.partnerId == partner.id).toList();

          if (displayVehicles.isEmpty) {
            return Center(child: Text(tr('no_vehicles', ref), style: const TextStyle(color: Colors.white38)));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingTextStyle: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 13),
              columns: [
                DataColumn(label: Text(tr('vehicle_details', ref))),
                DataColumn(label: Text(tr('transmission', ref))),
                DataColumn(label: Text(tr('fuel', ref))),
                DataColumn(label: Text(tr('hub_location', ref))),
                DataColumn(label: Text(tr('daily_rate', ref))),
                DataColumn(label: Text(tr('actions', ref))),
              ],
              rows: displayVehicles.map((vehicle) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              vehicle.imageUrl,
                              width: 50,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(width: 50, height: 38, color: Colors.grey[900], child: const Icon(Icons.car_crash, size: 16)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${vehicle.brand} ${vehicle.model}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('ID: ${vehicle.id.substring(0, 8)}...', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(vehicle.transmission, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(vehicle.fuelType, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(
                      Row(
                        children: [
                          Text(locationMap[vehicle.locationId] ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 13, color: Colors.white38),
                            onPressed: () => _showEditLocationDialog(context, ref, vehicle, locationsAsync.value ?? []),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Text('€${vehicle.pricePerDay.toStringAsFixed(0)}/d', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 13, color: Colors.white38),
                            onPressed: () => _showEditPriceDialog(context, ref, vehicle),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Color(0xFF00CEC9), size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditCarDialog(vehicle: vehicle),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            onPressed: () => _showDeleteVehicleDialog(context, ref, vehicle),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  // --- 8. Recent Bookings CRUD & Controls ---
  Widget _buildRecentBookingsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Booking>> bookingsAsync,
    AsyncValue<List<Vehicle>> vehiclesAsync,
    Partner? partner,
  ) {
    final vehicleMap = vehiclesAsync.maybeWhen(
      data: (list) => {for (var v in list) v.id: '${v.brand} ${v.model}'},
      orElse: () => <String, String>{},
    );

    return _SectionCard(
      title: tr('recent_bookings', ref),
      icon: Icons.calendar_month_outlined,
      action: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00CEC9),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          _showManualBookingDialog(context, ref, vehiclesAsync.value ?? [], partner);
        },
        icon: const Icon(Icons.add, size: 14, color: Colors.black),
        label: Text(tr('add_booking', ref), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      child: bookingsAsync.when(
        data: (bookings) {
          final displayVehiclesIds = vehiclesAsync.maybeWhen(
            data: (list) => partner == null ? list.map((v) => v.id).toSet() : list.where((v) => v.partnerId == partner.id).map((v) => v.id).toSet(),
            orElse: () => <String>{},
          );

          final filteredBookings = bookings.where((b) => displayVehiclesIds.contains(b.vehicleId)).toList();

          if (filteredBookings.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(tr('no_bookings', ref), style: const TextStyle(color: Colors.white30, fontSize: 13)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredBookings.length,
            separatorBuilder: (c, i) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              final vehicleName = vehicleMap[booking.vehicleId] ?? 'Premium Vehicle';
              final startStr = DateFormat('dd MMM yyyy').format(booking.startDate);
              final endStr = DateFormat('dd MMM yyyy').format(booking.endDate);

              final statusColor = booking.status == 'Confirmed'
                  ? Colors.green
                  : (booking.status == 'Cancelled' || booking.status == 'Rejected' ? Colors.redAccent : Colors.amber);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 550;

                    final infoContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tr('customer', ref)}: ${booking.fullName ?? "Guest"} • ${booking.phoneNumber ?? "N/A"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'Dates: $startStr - $endStr',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    );

                    final priceContent = Text(
                      '€${booking.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 15),
                    );

                    final statusActions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
                          color: const Color(0xFF16162B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (newStatus) async {
                            try {
                              await ref
                                  .read(adminBookingRepositoryProvider)
                                  .updateBookingStatus(booking.id, newStatus);

                              ref.invalidate(liveBookingsListProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF00CEC9),
                                    content: Text('Booking status updated to $newStatus'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    content: Text('Error updating booking: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(color: Colors.amber, fontSize: 13))),
                            const PopupMenuItem(value: 'Confirmed', child: Text('Confirmed', style: TextStyle(color: Colors.green, fontSize: 13))),
                            const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled', style: TextStyle(color: Colors.redAccent, fontSize: 13))),
                            const PopupMenuItem(value: 'Rejected', child: Text('Rejected', style: TextStyle(color: Colors.red, fontSize: 13))),
                          ],
                        ),
                      ],
                    );

                    if (isSmall) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          infoContent,
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              priceContent,
                              statusActions,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 3, child: infoContent),
                        Expanded(flex: 1, child: priceContent),
                        Expanded(flex: 2, child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [statusActions],
                        )),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  // --- Inline Fleet CRUD Helpers ---
  void _showEditPriceDialog(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    final controller = TextEditingController(text: vehicle.pricePerDay.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162B),
        title: Text('${tr('edit_rate_for', ref)} ${vehicle.brand} ${vehicle.model}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: tr('new_daily_rate', ref), labelStyle: const TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel', ref), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CEC9),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newRate = double.tryParse(controller.text.trim());
              if (newRate != null) {
                try {
                  await ref.read(vehicleRepositoryProvider).updateVehicleRate(vehicle.id, newRate);
                  ref.invalidate(vehiclesListProvider);
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                  }
                }
              }
            },
            child: Text(tr('save', ref)),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, WidgetRef ref, Vehicle vehicle, List<Location> locations) {
    Location? selected = locations.firstWhere((l) => l.id == vehicle.locationId, orElse: () => locations.first);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF16162B),
          title: Text('${tr('move', ref)} ${vehicle.brand}', style: const TextStyle(color: Colors.white)),
          content: DropdownButtonFormField<Location>(
            dropdownColor: const Color(0xFF16162B),
            value: selected,
            items: locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc.nameEn, style: const TextStyle(color: Colors.white)))).toList(),
            onChanged: (v) => setState(() => selected = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel', ref), style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CEC9),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (selected != null) {
                  try {
                    await ref.read(vehicleRepositoryProvider).updateVehicleLocation(vehicle.id, selected!.id);
                    ref.invalidate(vehiclesListProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: Text(tr('save', ref)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteVehicleDialog(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162B),
        title: Text(tr('delete_vehicle', ref), style: const TextStyle(color: Colors.white)),
        content: Text('${vehicle.brand} ${vehicle.model} — ${tr('remove_permanently', ref)}', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel', ref), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref.read(vehicleRepositoryProvider).deleteVehicle(vehicle.id);
                ref.invalidate(vehiclesListProvider);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                }
              }
            },
            child: Text(tr('delete', ref)),
          ),
        ],
      ),
    );
  }

  // --- Booking creation dialog ---
  void _showManualBookingDialog(BuildContext context, WidgetRef ref, List<Vehicle> vehicles, Partner? partner) {
    final formKey = GlobalKey<FormState>();
    final displayVehicles = partner == null ? vehicles : vehicles.where((v) => v.partnerId == partner.id).toList();

    Vehicle? selectedVehicle = displayVehicles.isNotEmpty ? displayVehicles.first : null;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final rateController = TextEditingController(text: selectedVehicle?.pricePerDay.toStringAsFixed(0) ?? '50');

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 3));
    String selectedStatus = 'Pending';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final days = endDate.difference(startDate).inDays;
          final total = (double.tryParse(rateController.text) ?? 50.0) * (days > 0 ? days : 1);

          return AlertDialog(
            backgroundColor: const Color(0xFF16162B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(tr('add_booking_manually', ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Vehicle Dropdown
                      DropdownButtonFormField<Vehicle>(
                        dropdownColor: const Color(0xFF16162B),
                        value: selectedVehicle,
                        decoration: InputDecoration(labelText: tr('select_vehicle', ref), labelStyle: const TextStyle(color: Colors.white60)),
                        items: displayVehicles.map((v) {
                          return DropdownMenuItem(value: v, child: Text('${v.brand} ${v.model} (${v.year})', style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedVehicle = v;
                            if (v != null) {
                              rateController.text = v.pricePerDay.toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: tr('customer_full_name', ref), labelStyle: const TextStyle(color: Colors.white60)),
                        validator: (v) => v == null || v.isEmpty ? tr('required', ref) : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: tr('phone_number', ref), labelStyle: const TextStyle(color: Colors.white60)),
                        validator: (v) => v == null || v.isEmpty ? tr('required', ref) : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(labelText: tr('email_address', ref), labelStyle: const TextStyle(color: Colors.white60)),
                        validator: (v) => v == null || !v.contains('@') ? tr('invalid', ref) : null,
                      ),
                      const SizedBox(height: 16),
                      // Dates row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('start_date', ref), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              OutlinedButton(
                                onPressed: () async {
                                  final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: startDate);
                                  if (d != null) setState(() => startDate = d);
                                },
                                child: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('end_date', ref), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              OutlinedButton(
                                onPressed: () async {
                                  final d = await showDatePicker(context: context, firstDate: startDate.add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: endDate.isAfter(startDate) ? endDate : startDate.add(const Duration(days: 1)));
                                  if (d != null) setState(() => endDate = d);
                                },
                                child: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF16162B),
                        value: selectedStatus,
                        decoration: InputDecoration(labelText: tr('status', ref), labelStyle: const TextStyle(color: Colors.white60)),
                        items: ['Pending', 'Confirmed', 'Cancelled', 'Rejected'].map((status) {
                          return DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (v) => setState(() => selectedStatus = v ?? 'Pending'),
                      ),
                      const SizedBox(height: 20),
                      // Total Estimate
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${tr('calculated_total', ref)} ($days ${tr('days', ref)}):', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          Text('€${total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('cancel', ref), style: const TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate() && selectedVehicle != null) {
                    try {
                      final manualBooking = Booking(
                        id: const Uuid().v4(),
                        vehicleId: selectedVehicle!.id,
                        userId: const Uuid().v4(),
                        startDate: startDate,
                        endDate: endDate,
                        totalPrice: total,
                        status: selectedStatus,
                        fullName: nameController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                        emailAddress: emailController.text.trim(),
                        language: ref.read(localeProvider),
                      );
                      await ref.read(bookingRepositoryProvider).submitBooking(manualBooking);
                      ref.invalidate(liveBookingsListProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: Text(tr('add_booking', ref)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPartnerDialog(BuildContext context, WidgetRef ref, Partner p) {
    final companyController = TextEditingController(text: p.companyName);
    final contactController = TextEditingController(text: p.contactName);
    final emailController = TextEditingController(text: p.email);
    final phoneController = TextEditingController(text: p.phone);
    bool autoConfirmValue = p.autoConfirm;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isSubActive = p.subscriptionStatus == 'Active';
          final subExpires = p.subscriptionExpiresAt;
          final expStr = subExpires != null ? DateFormat('dd MMM yyyy').format(subExpires) : 'N/A';

          return AlertDialog(
            backgroundColor: const Color(0xFF16162B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Partner: ${p.companyName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Company Name', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Contact Name', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Phone / Password', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Auto-Confirm Bookings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Switch(
                        value: autoConfirmValue,
                        activeColor: const Color(0xFF00CEC9),
                        onChanged: (val) {
                          setState(() {
                            autoConfirmValue = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subscription Status:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(
                              p.subscriptionStatus,
                              style: TextStyle(
                                color: isSubActive ? const Color(0xFF00CEC9) : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expires At:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(expStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: isSubActive
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await Supabase.instance.client
                                          .from('partners')
                                          .update({
                                            'subscription_status': 'Inactive',
                                            'subscription_expires_at': null,
                                            'paypal_subscription_id': null,
                                          })
                                          .eq('id', p.id);
                                      ref.invalidate(partnersListProvider);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription Stopped')));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                  child: const Text('Stop Subscription', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                    foregroundColor: Colors.greenAccent,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final exp = DateTime.now().add(const Duration(days: 30)).toIso8601String();
                                      await Supabase.instance.client
                                          .from('partners')
                                          .update({
                                            'subscription_status': 'Active',
                                            'subscription_expires_at': exp,
                                            'paypal_subscription_id': 'MANUAL_CASH',
                                          })
                                          .eq('id', p.id);
                                      ref.invalidate(partnersListProvider);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription Activated')));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                  child: const Text('Activate (Cash Payment)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await Supabase.instance.client
                        .from('partners')
                        .update({
                          'company_name': companyController.text.trim(),
                          'contact_name': contactController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'auto_confirm': autoConfirmValue,
                        })
                        .eq('id', p.id);
                    ref.invalidate(partnersListProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner updated successfully')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProfileSettingsDialog(BuildContext context, WidgetRef ref) async {
    final partner = ref.read(currentPartnerProvider);
    final isUserAdmin = partner == null;
    final supabase = ref.read(supabaseClientProvider);

    final emailController = TextEditingController();
    final passcodeController = TextEditingController();
    final companyController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    bool autoConfirmValue = false;

    if (isUserAdmin) {
      emailController.text = 'shaban.ejj@gmail.com';
      passcodeController.text = '2026';
      try {
        final res = await supabase.from('profiles').select().eq('role', 'Admin').single();
        emailController.text = res['email'] as String? ?? 'shaban.ejj@gmail.com';
        passcodeController.text = res['passcode'] as String? ?? '2026';
        autoConfirmValue = res['auto_confirm'] as bool? ?? false;
      } catch (_) {}
    } else {
      companyController.text = partner.companyName;
      contactController.text = partner.contactName;
      emailController.text = partner.email;
      phoneController.text = partner.phone;
      autoConfirmValue = partner.autoConfirm;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF16162B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isUserAdmin ? 'Admin Profile Settings' : 'Partner Profile Settings', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUserAdmin) ...[
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Admin Email', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passcodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Admin Passcode', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                ] else ...[
                  TextField(
                    controller: companyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Company Name', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Contact Name', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Phone / Password', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Auto-Confirm Bookings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Switch(
                      value: autoConfirmValue,
                      activeColor: const Color(0xFF00CEC9),
                      onChanged: (val) {
                        setState(() {
                          autoConfirmValue = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  if (isUserAdmin) {
                    await supabase.from('profiles').update({
                      'email': emailController.text.trim(),
                      'passcode': passcodeController.text.trim(),
                      'auto_confirm': autoConfirmValue,
                    }).eq('role', 'Admin');
                    ref.invalidate(profilesListProvider);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                    }
                  } else {
                    // Check if changes are made to profile fields
                    final hasChanges = companyController.text.trim() != partner.companyName ||
                        contactController.text.trim() != partner.contactName ||
                        emailController.text.trim() != partner.email ||
                        phoneController.text.trim() != partner.phone;

                    if (hasChanges) {
                      final req = ProfileChangeRequest(
                        id: '',
                        partnerId: partner.id,
                        companyName: companyController.text.trim(),
                        contactName: contactController.text.trim(),
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        status: 'Pending',
                        createdAt: DateTime.now(),
                      );
                      await ref.read(partnerRepositoryProvider).submitProfileChangeRequest(req);
                    }

                    // Update auto_confirm flag directly
                    final response = await supabase.from('partners').update({
                      'auto_confirm': autoConfirmValue,
                    }).eq('id', partner.id).select().single();

                    ref.read(currentPartnerProvider.notifier).state = Partner.fromJson(response);
                    ref.invalidate(partnersListProvider);
                    ref.invalidate(profileChangeRequestsListProvider);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (hasChanges) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: Color(0xFF00CEC9),
                          content: Text('Settings updated. Profile changes request submitted to Admin for approval.'),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Settings updated successfully!'),
                        ));
                      }
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Location Add Form (extracted because it needs hooks) ---
class _LocationAddForm extends HookConsumerWidget {
  final WidgetRef ref;
  const _LocationAddForm({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final codeController = useTextEditingController();
    final nameEnController = useTextEditingController();
    final nameSqController = useTextEditingController();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        final codeField = TextField(
          controller: codeController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: tr('id_label', widgetRef),
            labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        );

        final nameField = TextField(
          controller: nameEnController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: tr('location_name_en', widgetRef),
            labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        );

        final addButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00CEC9),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final code = codeController.text.trim();
            final nameEn = nameEnController.text.trim();
            if (code.isNotEmpty && nameEn.isNotEmpty) {
              try {
                final newLoc = Location(
                  id: '',
                  code: code,
                  nameEn: nameEn,
                  nameSq: nameSqController.text.isNotEmpty ? nameSqController.text.trim() : nameEn,
                  nameSr: nameEn, // Remove SR field & default to EN
                );
                await widgetRef.read(vehicleRepositoryProvider).addLocation(newLoc);
                widgetRef.invalidate(locationsProvider);
                codeController.clear();
                nameEnController.clear();
                nameSqController.clear();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                }
              }
            }
          },
          child: Text(tr('add', widgetRef), style: const TextStyle(fontWeight: FontWeight.bold)),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              codeField,
              const SizedBox(height: 12),
              nameField,
              const SizedBox(height: 16),
              addButton,
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(tr('add_translations', widgetRef), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                children: [
                  TextField(
                    controller: nameSqController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Name (AL)', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 1, child: codeField),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: nameField),
                const SizedBox(width: 12),
                addButton,
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text(tr('add_translations', widgetRef), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              children: [
                TextField(
                  controller: nameSqController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Name (AL)', labelStyle: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// --- Minor Widget Helpers ---
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF16162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF16162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final showVertical = action != null && constraints.maxWidth < 450;
              final titleRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF00CEC9), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Outfit',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );

              if (showVertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: titleRow)]),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: action!,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleRow),
                  if (action != null) ...[
                    const SizedBox(width: 8),
                    action!,
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
