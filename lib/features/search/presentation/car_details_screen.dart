import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../bookings/data/booking_repository.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';
import 'home_search_screen.dart';

class CarDetailsScreen extends ConsumerWidget {
  final String carId;
  final DateTime? startDate;
  final DateTime? endDate;

  const CarDetailsScreen({
    super.key,
    required this.carId,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final lang = locale.languageCode;

    final t = {
      'en': {
        'specs': 'Vehicle Specifications',
        'ac': 'Air Conditioning',
        'transmission': 'Transmission',
        'fuel': 'Fuel Type',
        'year': 'Year',
        'bookNow': 'Book Now',
        'bookingLoading': 'Checking Availability...',
        'success': 'Booking Successful!',
        'successMsg': 'Your premium rental is confirmed. Have a safe drive in Kosovo!',
        'error': 'Booking Failed',
        'errorMsg': 'This vehicle is unavailable for these dates.',
        'details': 'Car Details',
        'features': 'Included Premium Perks',
        'perk1': '24/7 Local Road Assistance',
        'perk2': 'Clean & Sanitized Cabin',
        'perk3': 'Full Casco Insurance Coverage',
      },
      'sq': {
        'specs': 'Specifikat e Automjetit',
        'ac': 'Kondicioner',
        'transmission': 'Transmisioni',
        'fuel': 'Lloji i Karburantit',
        'year': 'Viti',
        'bookNow': 'Rezervo Tani',
        'bookingLoading': 'Duke verifikuar...',
        'success': 'Rezervimi u Krye me Sukses!',
        'successMsg': 'Rezervimi juaj premium është konfirmuar. Udhëtim të mbarë në Kosovë!',
        'error': 'Rezervimi Dështoi',
        'errorMsg': 'Kjo makinë nuk është e disponueshme për këto data.',
        'details': 'Detajet e Makinës',
        'features': 'Përfitimet Premium',
        'perk1': 'Asistencë Rrugore Lokale 24/7',
        'perk2': 'Kabinë e Pastruar & Dezinfektuar',
        'perk3': 'Siguracion i Plotë Kasko',
      },
    }[lang]!;

    // Find the car using Riverpod state
    final vehiclesAsync = ref.watch(vehiclesListProvider());

    return Scaffold(
      body: vehiclesAsync.when(
        data: (vehicles) {
          final vehicle = vehicles.firstWhere(
            (v) => v.id == carId || v.id == 'v1', // Fallback to v1 for robustness
            orElse: () => vehicles.first,
          );

          final bookingState = ref.watch(bookingControllerProvider);
          final resolvedStart = startDate ?? DateTime.now().add(const Duration(days: 1));
          final resolvedEnd = endDate ?? DateTime.now().add(const Duration(days: 4));
          final durationDays = resolvedEnd.difference(resolvedStart).inDays;
          final calculatedDays = durationDays > 0 ? durationDays : 3;
          final totalPrice = vehicle.pricePerDay * calculatedDays;

          return Stack(
            children: [
              // Scrollable Details
              CustomScrollView(
                slivers: [
                  // App Bar with Image
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Image.network(
                        vehicle.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Info Section
                  SliverPadding(
                    padding: const EdgeInsets.all(20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${vehicle.brand} ${vehicle.model}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              '€${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00CEC9), // Neo Teal
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            const Text(
                              '4.9 (48 ratings)',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Specs Row / Grid
                        Text(
                          t['specs']!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _DetailSpecTile(icon: Icons.settings, title: t['transmission']!, value: vehicle.transmission),
                            _DetailSpecTile(icon: Icons.local_gas_station, title: t['fuel']!, value: vehicle.fuelType),
                            _DetailSpecTile(icon: Icons.calendar_today, title: t['year']!, value: '${vehicle.year}'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Perks List
                        Text(
                          t['features']!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        _PerkRow(text: t['perk1']!),
                        _PerkRow(text: t['perk2']!),
                        _PerkRow(text: t['perk3']!),

                        const SizedBox(height: 120), // Padding to prevent scroll overlay block
                      ]),
                    ),
                  ),
                ],
              ),

              // Booking Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16162B),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Estimated ($calculatedDays days)', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '€${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: bookingState.isLoading
                                  ? null
                                  : () {
                                      _showCompleteBookingDialog(
                                        context,
                                        ref,
                                        vehicle,
                                        resolvedStart,
                                        resolvedEnd,
                                        totalPrice,
                                        t,
                                      );
                                    },
                              child: bookingState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      t['bookNow']!,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))),
        error: (e, _) => Scaffold(body: Center(child: Text('Error loading car details: $e'))),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Map<String, String> t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00CEC9)),
            const SizedBox(width: 10),
            Text(t['success']!, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(t['successMsg']!, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss Dialog
              context.go('/'); // Back to search
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCompleteBookingDialog(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
    DateTime start,
    DateTime end,
    double totalPrice,
    Map<String, String> t,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final isSaving = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) {
        final startStr = DateFormat('MMM dd, yyyy').format(start);
        final endStr = DateFormat('MMM dd, yyyy').format(end);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16162B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Booking',
                    style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Provide contact details to finalize your reservation',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Vehicle Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  vehicle.imageUrl,
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 80,
                                    height: 60,
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.directions_car, color: Colors.white24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${vehicle.brand} ${vehicle.model}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '€${vehicle.pricePerDay.toStringAsFixed(0)} / day',
                                      style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dates display
                        const Text(
                          'Dates:',
                          style: TextStyle(color: Color(0xFF00CEC9), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$startStr - $endStr',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        // Input fields
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.white60),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                            prefixIcon: Icon(Icons.person_outline, color: Colors.white38),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your full name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: Colors.white60),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                            prefixIcon: Icon(Icons.phone_outlined, color: Colors.white38),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Please enter your phone number' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Colors.white60),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.white38),
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid email address' : null,
                        ),
                        const SizedBox(height: 24),

                        // Pricing detail
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Price:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                            Text(
                              '€${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving.value ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving.value
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isSaving.value = true;
                            });

                            final success = await ref
                                .read(bookingControllerProvider.notifier)
                                .bookVehicle(
                                  vehicleId: vehicle.id,
                                  startDate: start,
                                  endDate: end,
                                  totalPrice: totalPrice,
                                  fullName: nameController.text.trim(),
                                  phoneNumber: phoneController.text.trim(),
                                  emailAddress: emailController.text.trim(),
                                );

                            setState(() {
                              isSaving.value = false;
                            });

                            if (context.mounted) {
                              if (success) {
                                Navigator.of(context).pop(); // Dismiss Form Dialog
                                _showSuccessDialog(context, t);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red[800],
                                    content: Text(t['errorMsg']!),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DetailSpecTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailSpecTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00CEC9), size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  final String text;
  const _PerkRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF6C5CE7), size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
