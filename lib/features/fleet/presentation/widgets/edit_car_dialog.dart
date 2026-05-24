import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../search/data/vehicle_repository.dart';
import '../../../search/domain/location.dart';
import '../../../search/domain/vehicle.dart';

class EditCarDialog extends HookConsumerWidget {
  final Vehicle vehicle;

  const EditCarDialog({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    // Form Keys and Hooks Controllers pre-populated with vehicle details
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final brandController = useTextEditingController(text: vehicle.brand);
    final modelController = useTextEditingController(text: vehicle.model);
    final yearController = useTextEditingController(text: vehicle.year.toString());
    final rateController = useTextEditingController(text: vehicle.pricePerDay.toStringAsFixed(0));
    final imageUrlController = useTextEditingController();
    
    // Optional fields
    final seatsController = useTextEditingController(text: vehicle.seats?.toString() ?? '');
    final doorsController = useTextEditingController(text: vehicle.doors?.toString() ?? '');
    final engineController = useTextEditingController(text: vehicle.engine ?? '');
    final descriptionController = useTextEditingController(text: vehicle.description ?? '');

    final selectedLocation = useState<Location?>(null);
    final isAutomatic = useState<bool>(vehicle.transmission == 'Automatic');
    final selectedFuel = useState<String>(vehicle.fuelType);
    final hasAc = useState<bool>(vehicle.hasAc);
    final isSaving = useState<bool>(false);
    final errorMessage = useState<String?>(null);

    // Multiple image URLs list pre-populated
    final imageUrls = useState<List<String>>(List<String>.from(vehicle.imageUrls));

    // Pre-populate location when loaded
    useEffect(() {
      locationsAsync.whenData((locations) {
        if (selectedLocation.value == null && locations.isNotEmpty) {
          selectedLocation.value = locations.firstWhere(
            (l) => l.id == vehicle.locationId,
            orElse: () => locations.first,
          );
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

    Future<void> pickAndUploadImages() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true, // Required for Web to get bytes
        );

        if (result != null && result.files.isNotEmpty) {
          isSaving.value = true;
          errorMessage.value = null;

          final newUrls = <String>[];
          for (final file in result.files) {
            final bytes = file.bytes;
            if (bytes != null) {
              final url = await ref.read(vehicleRepositoryProvider).uploadVehicleImage(
                fileBytes: bytes,
                fileName: file.name,
              );
              newUrls.add(url);
            }
          }
          imageUrls.value = [...imageUrls.value, ...newUrls];
        }
      } catch (e) {
        errorMessage.value = 'Failed to upload image: $e';
      } finally {
        isSaving.value = false;
      }
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF16162B),
      title: Row(
        children: [
          const Icon(Icons.edit_road, color: Color(0xFF00CEC9)),
          const SizedBox(width: 10),
          const Text(
            'Edit Vehicle Details',
            style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
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
                const SizedBox(height: 12),

                // File Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: const Color(0xFF00CEC9),
                      side: const BorderSide(color: Color(0xFF00CEC9), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isSaving.value ? null : pickAndUploadImages,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload Local Images', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),

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

                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                const Text(
                  'Optional Specifications',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: seatsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seats (e.g. 5)',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: doorsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Doors (e.g. 5)',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: engineController,
                  decoration: const InputDecoration(
                    labelText: 'Engine Size (e.g. 2.0 TDI)',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / Premium Features Details',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  style: const TextStyle(color: Colors.white),
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
                  if (selectedLocation.value == null) {
                    errorMessage.value = 'Please select a location hub.';
                    return;
                  }
                  if (formKey.currentState!.validate()) {
                    // Require at least one image
                    final allUrls = List<String>.from(imageUrls.value);
                    final pendingUrl = imageUrlController.text.trim();
                    if (pendingUrl.isNotEmpty && pendingUrl.startsWith('http')) {
                      allUrls.add(pendingUrl);
                    }
                    if (allUrls.isEmpty) {
                      allUrls.add('https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=600');
                    }

                    isSaving.value = true;
                    errorMessage.value = null;

                    try {
                      final updated = Vehicle(
                        id: vehicle.id,
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
                        partnerId: vehicle.partnerId,
                        seats: int.tryParse(seatsController.text.trim()),
                        doors: int.tryParse(doorsController.text.trim()),
                        engine: engineController.text.trim().isNotEmpty ? engineController.text.trim() : null,
                        description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                      );

                      await ref.read(vehicleRepositoryProvider).updateVehicle(updated);
                      ref.invalidate(vehiclesListProvider);

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF00CEC9),
                            content: Text('Vehicle updated successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      errorMessage.value = e.toString();
                    } finally {
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
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
