import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/vehicle.dart';
import '../domain/location.dart';
import '../../bookings/data/booking_repository.dart';

part 'vehicle_repository.g.dart';

class VehicleRepository {
  final SupabaseClient _supabase;

  VehicleRepository(this._supabase);

  /// Fetch all active Kosovo hubs
  Future<List<Location>> fetchLocations() async {
    try {
      final response = await _supabase.from('locations').select();
      final list = response as List;
      return list.map((json) => Location.fromJson(json)).toList();
    } catch (e) {
      // Premium Mock fallback data for offline/standalone execution
      return [
        Location(
          id: 'l1', 
          nameEn: 'Pristina International Airport (PRN)', 
          nameSq: 'Aeroporti Ndërkombëtar i Prishtinës (PRN)', 
          nameSr: 'Međunarodni Aerodrom Priština (PRN)', 
          code: 'PRN'
        ),
        Location(
          id: 'l2', 
          nameEn: 'Pristina Center', 
          nameSq: 'Prishtinë Qendër', 
          nameSr: 'Priština Centar', 
          code: 'PR-CEN'
        ),
        Location(
          id: 'l3', 
          nameEn: 'Prizren Hub', 
          nameSq: 'Prizren Qendër', 
          nameSr: 'Prizren Centar', 
          code: 'PZ-HUB'
        ),
        Location(
          id: 'l4', 
          nameEn: 'Peja Hub', 
          nameSq: 'Pejë Qendër', 
          nameSr: 'Peć Centar', 
          code: 'PE-HUB'
        ),
      ];
    }
  }

  /// Fetch vehicles based on filter criteria
  Future<List<Vehicle>> fetchVehicles({String? locationId}) async {
    try {
      var query = _supabase.from('vehicles').select();
      if (locationId != null && locationId.isNotEmpty) {
        query = query.eq('location_id', locationId);
      }
      final response = await query;
      final list = response as List;
      return list.map((json) => Vehicle.fromJson(json)).toList();
    } catch (_) {
      // Premium Mock fallback vehicles
      final allMock = [
        Vehicle(
          id: 'v1',
          brand: 'Audi',
          model: 'A6 S-Line',
          year: 2023,
          transmission: 'Automatic',
          fuelType: 'Diesel',
          hasAc: true,
          pricePerDay: 65.0,
          imageUrl: 'https://images.unsplash.com/photo-1606016159991-dfe4f2746ad5?auto=format&fit=crop&q=80&w=600',
          locationId: 'l1',
        ),
        Vehicle(
          id: 'v2',
          brand: 'Volkswagen',
          model: 'Golf 8 R-Line',
          year: 2022,
          transmission: 'Automatic',
          fuelType: 'Petrol',
          hasAc: true,
          pricePerDay: 45.0,
          imageUrl: 'https://images.unsplash.com/photo-1617650728468-8581e439c864?auto=format&fit=crop&q=80&w=600',
          locationId: 'l1',
        ),
        Vehicle(
          id: 'v3',
          brand: 'BMW',
          model: '5 Series',
          year: 2023,
          transmission: 'Automatic',
          fuelType: 'Diesel',
          hasAc: true,
          pricePerDay: 75.0,
          imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=600',
          locationId: 'l2',
        ),
        Vehicle(
          id: 'v4',
          brand: 'Mercedes-Benz',
          model: 'C-Class',
          year: 2022,
          transmission: 'Automatic',
          fuelType: 'Diesel',
          hasAc: true,
          pricePerDay: 70.0,
          imageUrl: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&q=80&w=600',
          locationId: 'l3',
        ),
      ];
      if (locationId != null && locationId.isNotEmpty) {
        return allMock.where((v) => v.locationId == locationId).toList();
      }
      return allMock;
    }
  }

  /// Upload a vehicle image to Supabase Storage and return its public URL
  Future<String> uploadVehicleImage({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final ext = fileName.split('.').last;
    final path = 'vehicles/${const Uuid().v4()}.$ext';

    await _supabase.storage.from('vehicle-images').uploadBinary(
      path,
      fileBytes,
      fileOptions: FileOptions(
        contentType: 'image/$ext',
        upsert: true,
      ),
    );

    return _supabase.storage.from('vehicle-images').getPublicUrl(path);
  }

  /// Add a new vehicle to the Supabase database
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final response = await _supabase
        .from('vehicles')
        .insert({
          'brand': vehicle.brand,
          'model': vehicle.model,
          'year': vehicle.year,
          'transmission': vehicle.transmission,
          'fuel_type': vehicle.fuelType,
          'has_ac': vehicle.hasAc,
          'price_per_day': vehicle.pricePerDay,
          'image_url': vehicle.imageUrl,
          'image_urls': vehicle.imageUrls,
          'location_id': vehicle.locationId,
          'partner_id': vehicle.partnerId,
          'seats': vehicle.seats,
          'doors': vehicle.doors,
          'engine': vehicle.engine,
          'description': vehicle.description,
        })
        .select()
        .single();
    return Vehicle.fromJson(response);
  }

  /// Update an existing vehicle in the Supabase database
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final response = await _supabase
        .from('vehicles')
        .update({
          'brand': vehicle.brand,
          'model': vehicle.model,
          'year': vehicle.year,
          'transmission': vehicle.transmission,
          'fuel_type': vehicle.fuelType,
          'has_ac': vehicle.hasAc,
          'price_per_day': vehicle.pricePerDay,
          'image_url': vehicle.imageUrl,
          'image_urls': vehicle.imageUrls,
          'location_id': vehicle.locationId,
          'partner_id': vehicle.partnerId,
          'seats': vehicle.seats,
          'doors': vehicle.doors,
          'engine': vehicle.engine,
          'description': vehicle.description,
        })
        .eq('id', vehicle.id)
        .select()
        .single();
    return Vehicle.fromJson(response);
  }

  /// Update vehicle daily price rate
  Future<void> updateVehicleRate(String vehicleId, double newRate) async {
    await _supabase
        .from('vehicles')
        .update({'price_per_day': newRate})
        .eq('id', vehicleId);
  }

  /// Update vehicle location hub
  Future<void> updateVehicleLocation(String vehicleId, String newLocationId) async {
    await _supabase
        .from('vehicles')
        .update({'location_id': newLocationId})
        .eq('id', vehicleId);
  }

  /// Delete a vehicle from the fleet
  Future<void> deleteVehicle(String vehicleId) async {
    await _supabase
        .from('vehicles')
        .delete()
        .eq('id', vehicleId);
  }

  /// Add a new location hub
  Future<Location> addLocation(Location location) async {
    final response = await _supabase
        .from('locations')
        .insert({
          'name_en': location.nameEn,
          'name_sq': location.nameSq,
          'name_sr': location.nameSr,
          'code': location.code,
        })
        .select()
        .single();
    return Location.fromJson(response);
  }

  /// Delete a location hub
  Future<void> deleteLocation(String locationId) async {
    await _supabase
        .from('locations')
        .delete()
        .eq('id', locationId);
  }
}

@riverpod
VehicleRepository vehicleRepository(VehicleRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return VehicleRepository(client);
}

@Riverpod(keepAlive: true)
Future<List<Location>> locations(LocationsRef ref) {
  return ref.watch(vehicleRepositoryProvider).fetchLocations();
}

@Riverpod(keepAlive: true)
Future<List<Vehicle>> vehiclesList(VehiclesListRef ref, {String? locationId}) {
  return ref.watch(vehicleRepositoryProvider).fetchVehicles(locationId: locationId);
}
