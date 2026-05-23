import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/vehicle_repository.dart';
import 'home_search_screen.dart';
import 'widgets/car_card.dart';

class SearchResultsScreen extends ConsumerWidget {
  final String? locationId;
  final DateTime? startDate;
  final DateTime? endDate;

  const SearchResultsScreen({
    super.key,
    this.locationId,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final lang = locale.languageCode;

    final t = {
      'en': {
        'title': 'Available Fleet',
        'subtitle': 'Select a premium car to start your booking',
        'empty': 'No premium vehicles found in this location.',
        'back': 'Back',
      },
      'sq': {
        'title': 'Flota e Disponueshme',
        'subtitle': 'Zgjidhni një makinë premium për të rezervuar',
        'empty': 'Nuk u gjet asnjë automjet premium në këtë vendndodhje.',
        'back': 'Mbrapa',
      },
    }[lang]!;

    final vehiclesAsync = ref.watch(vehiclesListProvider(locationId: locationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t['title']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF16162B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: vehiclesAsync.when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 20),
                      Text(
                        t['empty']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    t['subtitle']!,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      return CarCard(vehicle: vehicles[index]);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
          error: (e, _) => Center(
            child: Text(
              'Error loading vehicles: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }
}
