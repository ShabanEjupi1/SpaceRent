import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../search/data/vehicle_repository.dart';
import '../../../search/domain/location.dart';
import '../../../search/domain/vehicle.dart';

// Web file picker helper — uses dart:html on web
// For mobile, you'd use file_picker or image_picker package
// This implementation works for web deployments
class PickedImage {
  final String name;
  final Uint8List bytes;
  PickedImage({required this.name, required this.bytes});
}

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
    final imageUrlController = useTextEditingController();

    final selectedLocation = useState<Location?>(null);
    final isAutomatic = useState<bool>(true);
    final selectedFuel = useState<String>('Diesel');
    final hasAc = useState<bool>(true);
    final isSaving = useState<bool>(false);
    final errorMessage = useState<String?>(null);

    // Multiple image URLs list
    final imageUrls = useState<List<String>>([]);

    // Pre-populate first location when loaded
    useEffect(() {
      locationsAsync.whenData((locations) {
        if (selectedLocation.value == null && locations.isNotEmpty) {
          selectedLocation.value = locations.first;
        }
      });
      return null;
    }, [locationsAsync]);

    void addImageUrl() {
      final url = imageUrlController.text.trim();
      if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
        imageUrls.value = [...imageUrls.value, url];
        imageUrlController.clear();
      }
    }

    void removeImageUrl(int index) {
      final newList = List<String>.from(imageUrls.value);
      newList.removeAt(index);
      imageUrls.value = newList;
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF16162B),
      title: Row(
        children: [
          const Icon(Icons.directions_car, color: Color(0xFF00CEC9)),
          const SizedBox(width: 10),
          Text(
            tr('add_new_fleet_vehicle', ref),
            style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error message
                if (errorMessage.value != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMessage.value!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                      ],
                    ),
                  ),
                ],

                // Brand & Model
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: brandController,
                        decoration: InputDecoration(
                          labelText: tr('brand_label', ref),
                          labelStyle: const TextStyle(color: Colors.white60),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || v.isEmpty ? tr('required', ref) : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: modelController,
                        decoration: InputDecoration(
                          labelText: tr('model_label', ref),
                          labelStyle: const TextStyle(color: Colors.white60),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || v.isEmpty ? tr('required', ref) : null,
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
                        decoration: InputDecoration(
                          labelText: tr('year', ref),
                          labelStyle: const TextStyle(color: Colors.white60),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || int.tryParse(v) == null ? tr('invalid', ref) : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('daily_rate_label', ref),
                          labelStyle: const TextStyle(color: Colors.white60),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v == null || double.tryParse(v) == null ? tr('invalid', ref) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Vehicle Images Section
                Text(
                  tr('vehicle_images', ref),
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),

                // Image URL input with Add button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageUrlController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: tr('or_add_url', ref),
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF00CEC9), size: 22),
                            onPressed: addImageUrl,
                          ),
                        ),
                        onSubmitted: (_) => addImageUrl(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Image previews grid
                if (imageUrls.value.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.value.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrls.value[index],
                                  width: 100,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 100,
                                    height: 75,
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.broken_image, color: Colors.white30, size: 20),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => removeImageUrl(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${imageUrls.value.length} image(s) added',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 16),

                // Hub Location Dropdown
                locationsAsync.when(
                  data: (locations) => DropdownButtonFormField<Location>(
                    dropdownColor: const Color(0xFF16162B),
                    value: selectedLocation.value,
                    decoration: InputDecoration(
                      labelText: tr('location_hub', ref),
                      labelStyle: const TextStyle(color: Colors.white60),
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
                        Text(tr('transmission_label', ref), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Row(
                          children: [
                            Text(tr('manual', ref), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Switch(
                              value: isAutomatic.value,
                              activeColor: const Color(0xFF00CEC9),
                              onChanged: (val) => isAutomatic.value = val,
                            ),
                            Text(tr('automatic', ref), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),

                    // AC Toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('ac_unit', ref), style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                  decoration: InputDecoration(
                    labelText: tr('fuel_type', ref),
                    labelStyle: const TextStyle(color: Colors.white60),
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
          child: Text(tr('cancel', ref), style: const TextStyle(color: Colors.white54)),
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
                    // Require at least one image
                    final allUrls = List<String>.from(imageUrls.value);
                    final pendingUrl = imageUrlController.text.trim();
                    if (pendingUrl.isNotEmpty && pendingUrl.startsWith('http')) {
                      allUrls.add(pendingUrl);
                    }
                    if (allUrls.isEmpty) {
                      // Use a default placeholder if no image provided
                      allUrls.add('https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=600');
                    }

                    isSaving.value = true;
                    errorMessage.value = null;

                    try {
                      final vehicle = Vehicle(
                        id: const Uuid().v4(),
                        brand: brandController.text.trim(),
                        model: modelController.text.trim(),
                        year: int.parse(yearController.text.trim()),
                        transmission: isAutomatic.value ? 'Automatic' : 'Manual',
                        fuelType: selectedFuel.value,
                        hasAc: hasAc.value,
                        pricePerDay: double.parse(rateController.text.trim()),
                        imageUrl: allUrls.first,
                        imageUrls: allUrls,
                        locationId: selectedLocation.value!.id,
                      );

                      await ref.read(vehicleRepositoryProvider).addVehicle(vehicle);
                      ref.invalidate(vehiclesListProvider);

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF00CEC9),
                            content: Text(tr('vehicle_added', ref)),
                          ),
                        );
                      }
                    } catch (e) {
                      errorMessage.value = e.toString();
                      isSaving.value = false;
                    }
                  }
                },
          child: isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(tr('save_vehicle', ref)),
        ),
      ],
    );
  }
}
