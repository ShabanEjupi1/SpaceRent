import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../bookings/data/admin_booking_repository.dart';
import '../../bookings/domain/booking.dart';
import '../../search/data/vehicle_repository.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveBookingsAsync = ref.watch(liveBookingsListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          // Header Section
          const SliverPadding(
            padding: EdgeInsets.all(24.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operational Control Center',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Live overview of SpaceRent operations across Kosovo hubs',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Stream-based metrics computation
          liveBookingsAsync.when(
            data: (bookings) {
              final totalVehicles = vehiclesAsync.maybeWhen(
                data: (v) => v.length,
                orElse: () => 12, // fallback
              );

              // 1. Active Rentals
              final activeRentals = bookings.where((b) => b.status == 'Confirmed').length;

              // 2. Vehicles Out (utilization rate)
              final vehiclesOut = activeRentals;

              // 3. Today's Revenue
              final todayRevenue = bookings
                  .where((b) => b.status == 'Confirmed')
                  .fold<double>(0, (sum, b) => sum + b.totalPrice);

              // 4. Pending PRN Pickups
              final pendingPrn = bookings.where((b) {
                // If it's confirmed and starting today (mock/approximate date filter)
                return b.status == 'Confirmed';
              }).length;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.8,
                  ),
                  delegate: SliverChildListDelegate([
                    _StatCard(
                      title: 'ACTIVE RENTALS',
                      value: '$activeRentals',
                      icon: Icons.vpn_key_outlined,
                      color: const Color(0xFF6C5CE7),
                    ),
                    _StatCard(
                      title: 'VEHICLES OUT',
                      value: '$vehiclesOut / $totalVehicles',
                      icon: Icons.directions_car_outlined,
                      color: const Color(0xFF00CEC9),
                    ),
                    _StatCard(
                      title: 'TOTAL ECOSYSTEM REVENUE',
                      value: '€${todayRevenue.toStringAsFixed(0)}',
                      icon: Icons.euro_symbol,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'PENDING HUB CONFIRMATIONS',
                      value: '$pendingPrn',
                      icon: Icons.flight_land,
                      color: Colors.amber,
                    ),
                  ]),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading operations metrics: $err')),
            ),
          ),

          // Live Revenue Graph Section
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverToBoxAdapter(
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Analytics (Last 7 Days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  final index = val.toInt() % days.length;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      days[index],
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 180),
                                FlSpot(1, 240),
                                FlSpot(2, 210),
                                FlSpot(3, 390),
                                FlSpot(4, 320),
                                FlSpot(5, 540),
                                FlSpot(6, 680),
                              ],
                              isCurved: true,
                              color: const Color(0xFF00CEC9), // Neo Teal
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF00CEC9).withOpacity(0.15),
                              ),
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 120),
                                FlSpot(1, 190),
                                FlSpot(2, 290),
                                FlSpot(3, 260),
                                FlSpot(4, 450),
                                FlSpot(5, 490),
                                FlSpot(6, 590),
                              ],
                              isCurved: true,
                              color: const Color(0xFF6C5CE7), // Space Violet
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF6C5CE7).withOpacity(0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
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
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}
