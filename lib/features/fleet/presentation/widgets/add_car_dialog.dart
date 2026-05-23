import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../search/data/vehicle_repository.dart';
import '../../../search/domain/location.dart';
import '../../../search/domain/vehicle.dart';

class AddCarDialog extends HookConsumerWidget {
  const AddCarDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    // Form Keys and Hooks Controllers
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final brandController = useTextEditingController();
    final modelController = useTextEditingController();
    final yearController = useTextEditingController(text: DateTime.now().year.toString());
    final rateController = useTextEditingController();
    final imageController = useTextEditingController(
      text: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=600',
    );

    final selectedLocation = useState<Location?>(null);
    final isAutomatic = useState<bool>(true);
    final selectedFuel = useState<String>('Diesel');
    final hasAc = useState<bool>(true);
    final isSaving = useState<bool>(false);

    // Pre-populate first location when loaded
    useEffect(() {
      locationsAsync.whenData((locations) {
        if (selectedLocation.value == null && locations.isNotEmpty) {
          selectedLocation.value = locations.first;
        }
      });
      return null;
    }, [locationsAsync]);

    return AlertDialog(
      backgroundColor: const Color(0xFF16162B),
      title: const Row(
        children: [
          Icon(Icons.directions_car, color: Color(0xFF00CEC9)),
          SizedBox(width: 10),
          Text(
            'Add New Fleet Vehicle',
            style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand & Model
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand (e.g. Audi)',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model (e.g. A6)',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Year & Rate
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: rateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Daily Rate (€)',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image URL
                TextFormField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Image URL',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Hub Location Dropdown
                locationsAsync.when(
                  data: (locations) => DropdownButtonFormField<Location>(
                    dropdownColor: const Color(0xFF16162B),
                    value: selectedLocation.value,
                    decoration: const InputDecoration(
                      labelText: 'Location Hub',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                    items: locations.map((loc) {
                      return DropdownMenuItem<Location>(
                        value: loc,
                        child: Text(loc.nameEn, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) => selectedLocation.value = val,
                  ),
                  error: (_, __) => const Text('Error loading hubs', style: TextStyle(color: Colors.redAccent)),
                  loading: () => const CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                ),
                const SizedBox(height: 20),

                // Transmission & Fuel Type & AC
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Transmission Toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transmission', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Row(
                          children: [
                            const Text('Manual', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Switch(
                              value: isAutomatic.value,
                              activeColor: const Color(0xFF00CEC9),
                              onChanged: (val) => isAutomatic.value = val,
                            ),
                            const Text('Automatic', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),

                    // AC Toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('A/C Unit', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Checkbox(
                          value: hasAc.value,
                          activeColor: const Color(0xFF6C5CE7),
                          onChanged: (val) => hasAc.value = val ?? true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fuel Type Dropdown
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF16162B),
                  value: selectedFuel.value,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Type',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  items: ['Diesel', 'Petrol', 'Electric', 'Hybrid'].map((fuel) {
                    return DropdownMenuItem<String>(
                      value: fuel,
                      child: Text(fuel, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) => selectedFuel.value = val ?? 'Diesel',
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
          ),
          onPressed: isSaving.value
              ? null
              : () async {
                  if (formKey.currentState!.validate() && selectedLocation.value != null) {
                    isSaving.value = true;
                    final vehicle = Vehicle(
                      id: const Uuid().v4(),
                      brand: brandController.text.trim(),
                      model: modelController.text.trim(),
                      year: int.parse(yearController.text.trim()),
                      transmission: isAutomatic.value ? 'Automatic' : 'Manual',
                      fuelType: selectedFuel.value,
                      hasAc: hasAc.value,
                      pricePerDay: double.parse(rateController.text.trim()),
                      imageUrl: imageController.text.trim(),
                      locationId: selectedLocation.value!.id,
                    );

                    await ref.read(vehicleRepositoryProvider).addVehicle(vehicle);
                    ref.invalidate(vehiclesListProvider); // Force reload fleets list

                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close Dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF00CEC9),
                          content: Text('Vehicle added successfully to fleet!'),
                        ),
                      );
                    }
                  }
                },
          child: isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save Vehicle'),
        ),
      ],
    );
  }
}
