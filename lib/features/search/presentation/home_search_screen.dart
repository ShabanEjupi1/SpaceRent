import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../fleet/data/partner_repository.dart';
import '../data/vehicle_repository.dart';
import '../domain/location.dart';

// Simple global StateProvider for app locale handling Kosovo localization
final appLocaleProvider = StateProvider<Locale>((ref) => const Locale('en', 'US'));

class HomeSearchScreen extends HookConsumerWidget {
  const HomeSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);
    final lang = currentLocale.languageCode;

    // Localized Strings
    final t = {
      'en': {
        'title': 'SpaceRent Kosovo',
        'subtitle': 'Premium Car Rentals in Pristina, Prizren & Peja',
        'locationLabel': 'Pickup Location',
        'datesLabel': 'Rental Dates',
        'searchBtn': 'Find Your Ride',
        'selectDate': 'Select date range',
        'days': 'days',
      },
      'sq': {
        'title': 'SpaceRent Kosovë',
        'subtitle': 'Makina me Qira Premium në Prishtinë, Prizren & Pejë',
        'locationLabel': 'Vendi i Marrjes',
        'datesLabel': 'Periudha e Qirasë',
        'searchBtn': 'Gjej Automjetin',
        'selectDate': 'Zgjidh periudhën',
        'days': 'ditë',
      },
    }[lang]!;

    // Fetch locations from repository using Riverpod
    final locationsAsync = ref.watch(locationsProvider);

    // Selected state using hooks
    final selectedLocation = useState<Location?>(null);
    final dateRange = useState<DateTimeRange?>(null);

    // Initialize/Prioritize PRN Airport when locations load
    useEffect(() {
      locationsAsync.whenData((locations) {
        if (selectedLocation.value == null && locations.isNotEmpty) {
          // Find Pristina Airport (PRN)
          final prn = locations.firstWhere(
            (loc) => loc.code == 'PRN',
            orElse: () => locations.first,
          );
          selectedLocation.value = prn;
        }
      });
      return null;
    }, [locationsAsync]);

    // Format dates helper
    String getFormattedDates() {
      if (dateRange.value == null) return t['selectDate']!;
      final formatter = DateFormat('dd MMM yyyy', lang);
      final start = formatter.format(dateRange.value!.start);
      final end = formatter.format(dateRange.value!.end);
      final days = dateRange.value!.duration.inDays;
      return '$start - $end ($days ${t['days']})';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF1E1E3F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onDoubleTap: () => _showAdminPasscodeDialog(context, ref),
                            child: Text(
                              t['title']!,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t['subtitle']!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                      // Language Selector Flag/Button
                      _LanguageSelector(currentLocale: currentLocale),
                    ],
                  ),
                ),
              ),

              // Search Form Container with Premium Glassmorphism styling
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Picker Title
                        Text(
                          t['locationLabel']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00CEC9), // Neo Teal
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dropdown or loading indicator
                        locationsAsync.when(
                          data: (locations) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Location>(
                                dropdownColor: const Color(0xFF1A1A2E),
                                isExpanded: true,
                                value: selectedLocation.value,
                                icon: const Icon(Icons.location_on_outlined, color: Color(0xFF6C5CE7)),
                                items: locations.map((loc) {
                                  return DropdownMenuItem<Location>(
                                    value: loc,
                                    child: Text(
                                      loc.getLocalizedName(lang),
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  selectedLocation.value = value;
                                },
                              ),
                            ),
                          ),
                          error: (e, _) => Center(child: Text('Error loading locations', style: TextStyle(color: Colors.red[300]))),
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
                        ),

                        const SizedBox(height: 24),

                        // Dates Selector Title
                        Text(
                          t['datesLabel']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00CEC9), // Neo Teal
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Date Selector Trigger Button
                        InkWell(
                          onTap: () async {
                            final pickedRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDateRange: dateRange.value,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF6C5CE7),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF1A1A2E),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedRange != null) {
                              dateRange.value = pickedRange;
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: Color(0xFF6C5CE7), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    getFormattedDates(),
                                    style: TextStyle(
                                      color: dateRange.value == null ? Colors.white38 : Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action Search Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                              shadowColor: const Color(0xFF6C5CE7).withOpacity(0.5),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              if (selectedLocation.value != null && dateRange.value != null) {
                                context.pushNamed(
                                  'search_results',
                                  queryParameters: {
                                    'locationId': selectedLocation.value!.id,
                                    'start': dateRange.value!.start.toIso8601String(),
                                    'end': dateRange.value!.end.toIso8601String(),
                                  },
                                );
                              } else if (dateRange.value == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red[800],
                                    content: Text(
                                      lang == 'sq' ? 'Ju lutem zgjidhni datat!' : 'Please select dates!',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t['searchBtn']!,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Aesthetic Promotional Cards / Quick Grid
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Explore Kosovo with SpaceRent',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 12),
                    const _PromotionalCard(
                      icon: Icons.flight_land,
                      title: 'Direct Hub at PRN Airport',
                      description: 'No waiting lines. Skip the queue and hop into your premium vehicle directly at Pristina International Airport.',
                    ),
                    const SizedBox(height: 12),
                    const _PromotionalCard(
                      icon: Icons.security,
                      title: 'Full Casco Protection',
                      description: 'Drive stress-free through Rugova Canyon, Brezovica, or Prizren Castle with comprehensive local insurance coverage.',
                    ),
                    const SizedBox(height: 12),
                    _PromotionalCard(
                      icon: Icons.handshake_outlined,
                      title: 'Become a SpaceRent Partner',
                      description: 'Own a vehicle fleet in Kosovo? Apply to become a verified operator and accept digital reservations.',
                      onTap: () => context.push('/partner/apply'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminPasscodeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162B),
        title: const Text('Admin Access Verification', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter Admin Passcode',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              final input = controller.text.trim();
              bool isValid = false;
              try {
                final response = await Supabase.instance.client
                    .from('profiles')
                    .select()
                    .eq('role', 'Admin');
                if (response.isNotEmpty) {
                  final adminProfile = response.first;
                  final dbPass = adminProfile['passcode'] as String?;
                  if (dbPass != null && dbPass.isNotEmpty) {
                    isValid = (input == dbPass);
                  } else {
                    isValid = (input == '2026');
                  }
                } else {
                  isValid = (input == '2026');
                }
              } catch (_) {
                isValid = (input == '2026');
              }

              if (isValid) {
                ref.read(isAdminProvider.notifier).state = true;
                Navigator.of(context).pop();
                context.go('/admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text('Access Denied: Invalid Passcode'),
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  final Locale currentLocale;
  const _LanguageSelector({required this.currentLocale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String getFlagEmoji(String countryCode) {
      if (countryCode == 'en') return '🇺🇸 EN';
      if (countryCode == 'sq') return '🇽🇰 AL';
      return countryCode.toUpperCase();
    }

    return PopupMenuButton<Locale>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Text(
              getFlagEmoji(currentLocale.languageCode),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
          ],
        ),
      ),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (Locale locale) {
        ref.read(appLocaleProvider.notifier).state = locale;
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: Locale('en', 'US'),
          child: Text('English', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: Locale('sq', 'XK'),
          child: Text('Shqip', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _PromotionalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _PromotionalCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onTap != null
                ? const Color(0xFF6C5CE7).withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: onTap != null ? const Color(0xFF00CEC9) : const Color(0xFF00CEC9),
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                      if (onTap != null)
                        const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF00CEC9)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
