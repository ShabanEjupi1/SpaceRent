import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/vehicle.dart';

class CarCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const CarCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.pushNamed('car_details', pathParameters: {'id': vehicle.id}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image Section with Price Tag Overlay
            Stack(
              children: [
                Image.network(
                  vehicle.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[900],
                    child: const Icon(Icons.directions_car, size: 60, color: Colors.white24),
                  ),
                ),
                // Gradient tint on image bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Price Tag Overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '€${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Vehicle Specs and Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand and Model
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      Text(
                        '${vehicle.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal list of customized vehicle specs (Transmission, Fuel, AC)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SpecBadge(
                        icon: Icons.settings,
                        label: vehicle.transmission,
                      ),
                      _SpecBadge(
                        icon: Icons.local_gas_station,
                        label: vehicle.fuelType,
                      ),
                      if (vehicle.hasAc)
                        const _SpecBadge(
                          icon: Icons.ac_unit,
                          label: 'A/C',
                        ),
                      if (vehicle.seats != null)
                        _SpecBadge(
                          icon: Icons.airline_seat_recline_normal,
                          label: '${vehicle.seats} Seats',
                        ),
                      if (vehicle.doors != null)
                        _SpecBadge(
                          icon: Icons.sensor_door,
                          label: '${vehicle.doors} Doors',
                        ),
                    ],
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

class _SpecBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00CEC9)), // Neo Teal Highlight
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
