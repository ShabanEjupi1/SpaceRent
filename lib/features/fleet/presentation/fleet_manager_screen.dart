import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../search/data/vehicle_repository.dart';
import '../../search/domain/vehicle.dart';
import '../../search/domain/location.dart';
import 'widgets/add_car_dialog.dart';

class FleetManagerScreen extends HookConsumerWidget {
  const FleetManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesListProvider());
    final locationsAsync = ref.watch(locationsProvider);

    final filterLocationId = useState<String?>(null);

    // Map locations for fast lookup
    final locationMap = locationsAsync.maybeWhen(
      data: (list) => {for (var loc in list) loc.id: loc.nameEn},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Fleet Management',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          // Filter Location Dropdown
          locationsAsync.maybeWhen(
            data: (locations) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: DropdownButton<String?>(
                dropdownColor: const Color(0xFF16162B),
                underline: const SizedBox(),
                value: filterLocationId.value,
                hint: const Text('Filter by Location Hub', style: TextStyle(color: Colors.white70, fontSize: 13)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Hubs', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  ...locations.map((loc) => DropdownMenuItem<String?>(
                        value: loc.id,
                        child: Text(loc.nameEn, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      )),
                ],
                onChanged: (val) => filterLocationId.value = val,
              ),
            ),
            orElse: () => const SizedBox(),
          ),

          // Manage Location Hubs Button
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00CEC9),
                side: const BorderSide(color: Color(0xFF00CEC9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _showManageHubsDialog(context, ref);
              },
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Manage Hubs', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          // Add New Vehicle Button
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddCarDialog(),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
          child: vehiclesAsync.when(
            data: (vehicles) {
              // Apply local filters
              final filteredVehicles = filterLocationId.value == null
                  ? vehicles
                  : vehicles.where((v) => v.locationId == filterLocationId.value).toList();

              if (filteredVehicles.isEmpty) {
                return const Center(
                  child: Text('No vehicles found matching filter criteria.', style: TextStyle(color: Colors.white54)),
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
                      DataColumn(label: Text('Photo')),
                      DataColumn(label: Text('Brand / Model')),
                      DataColumn(label: Text('Year')),
                      DataColumn(label: Text('Transmission')),
                      DataColumn(label: Text('Fuel Type')),
                      DataColumn(label: Text('A/C')),
                      DataColumn(label: Text('Location Hub')),
                      DataColumn(label: Text('Daily Rate')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: filteredVehicles.map((vehicle) {
                      return DataRow(
                        cells: [
                          // Photo
                          DataCell(
                            Container(
                              width: 44,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                image: DecorationImage(
                                  image: NetworkImage(vehicle.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Brand & Model
                          DataCell(
                            Text('${vehicle.brand} ${vehicle.model}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                          // Year
                          DataCell(Text('${vehicle.year}', style: const TextStyle(color: Colors.white70))),
                          // Transmission
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vehicle.transmission == 'Automatic'
                                    ? const Color(0xFF00CEC9).withOpacity(0.1)
                                    : Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vehicle.transmission,
                                style: TextStyle(
                                  color: vehicle.transmission == 'Automatic' ? const Color(0xFF00CEC9) : Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Fuel Type
                          DataCell(Text(vehicle.fuelType, style: const TextStyle(color: Colors.white70))),
                          // AC
                          DataCell(
                            Icon(
                              vehicle.hasAc ? Icons.check_circle : Icons.cancel_outlined,
                              color: vehicle.hasAc ? const Color(0xFF00CEC9) : Colors.white30,
                              size: 18,
                        ),
                      ),
                      // Location Hub
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(locationMap[vehicle.locationId] ?? 'Unknown Hub',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 14, color: Colors.white38),
                              onPressed: () {
                                _showEditLocationDialog(context, ref, vehicle);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Daily Rate Inline Editing/Display
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('€${vehicle.pricePerDay.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 14, color: Colors.white38),
                              onPressed: () {
                                _showEditRateDialog(context, ref, vehicle);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          onPressed: () {
                            _showDeleteVehicleDialog(context, ref, vehicle);
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
        error: (e, _) => Center(child: Text('Error loading fleet: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    ),
  ),
);
}

  void _showEditRateDialog(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    final controller = TextEditingController(text: vehicle.pricePerDay.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162B),
        title: Text('Edit Rate for ${vehicle.brand} ${vehicle.model}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Daily Rate (€)',
            labelStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CEC9),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newRate = double.tryParse(controller.text.trim());
              if (newRate != null) {
                await ref.read(vehicleRepositoryProvider).updateVehicleRate(vehicle.id, newRate);
                ref.invalidate(vehiclesListProvider); // Refresh Table Grid
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    final locationsAsync = ref.read(locationsProvider);
    locationsAsync.whenData((locations) {
      showDialog(
        context: context,
        builder: (context) {
          Location? selectedLoc = locations.firstWhere((loc) => loc.id == vehicle.locationId, orElse: () => locations.first);
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF16162B),
                title: Text('Change Location for ${vehicle.brand} ${vehicle.model}', style: const TextStyle(color: Colors.white)),
                content: DropdownButtonFormField<Location>(
                  dropdownColor: const Color(0xFF16162B),
                  value: selectedLoc,
                  decoration: const InputDecoration(
                    labelText: 'Select New Hub',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  items: locations.map((loc) {
                    return DropdownMenuItem<Location>(
                      value: loc,
                      child: Text(loc.nameEn, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedLoc = val;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CEC9), foregroundColor: Colors.white),
                    onPressed: () async {
                      if (selectedLoc != null) {
                        await ref.read(vehicleRepositoryProvider).updateVehicleLocation(vehicle.id, selectedLoc!.id);
                        ref.invalidate(vehiclesListProvider);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            }
          );
        }
      );
    });
  }

  void _showDeleteVehicleDialog(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162B),
        title: const Text('Delete Vehicle', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove ${vehicle.brand} ${vehicle.model} (${vehicle.year}) from the SpaceRent fleet?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(vehicleRepositoryProvider).deleteVehicle(vehicle.id);
              ref.invalidate(vehiclesListProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showManageHubsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final nameEnController = TextEditingController();
        final nameSqController = TextEditingController();
        final nameSrController = TextEditingController();
        final codeController = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setState) {
            final locsAsync = ref.watch(locationsProvider);

            return AlertDialog(
              backgroundColor: const Color(0xFF16162B),
              title: const Row(
                children: [
                  Icon(Icons.map, color: Color(0xFF00CEC9)),
                  SizedBox(width: 10),
                  Text('Manage Location Hubs', style: TextStyle(color: Colors.white, fontFamily: 'Outfit')),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 450,
                child: Column(
                  children: [
                    Expanded(
                      child: locsAsync.when(
                        data: (locations) => ListView.builder(
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final loc = locations[index];
                            return ListTile(
                              title: Text(loc.nameEn, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              subtitle: Text('Code: ${loc.code}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                onPressed: () async {
                                  await ref.read(vehicleRepositoryProvider).deleteLocation(loc.id);
                                  ref.invalidate(locationsProvider);
                                },
                              ),
                            );
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Add New Hub', style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 14)),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: nameEnController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name (EN)',
                                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: codeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Code (e.g. GJK)',
                                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: nameSqController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name (SQ)',
                                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: nameSrController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name (SR)',
                                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final newLoc = Location(
                                      id: '',
                                      nameEn: nameEnController.text.trim(),
                                      nameSq: nameSqController.text.trim(),
                                      nameSr: nameSrController.text.trim(),
                                      code: codeController.text.trim(),
                                    );
                                    await ref.read(vehicleRepositoryProvider).addLocation(newLoc);
                                    ref.invalidate(locationsProvider);
                                    nameEnController.clear();
                                    nameSqController.clear();
                                    nameSrController.clear();
                                    codeController.clear();
                                  }
                                },
                                child: const Text('Add Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
