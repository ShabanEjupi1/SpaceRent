import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    } catch (_) {
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

  /// Add a new vehicle to the Supabase database
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    try {
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
            'location_id': vehicle.locationId,
            'partner_id': vehicle.partnerId,
          })
          .select()
          .single();
      return Vehicle.fromJson(response);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return vehicle;
      }
      rethrow;
    }
  }

  /// Update vehicle daily price rate
  Future<void> updateVehicleRate(String vehicleId, double newRate) async {
    try {
      await _supabase
          .from('vehicles')
          .update({'price_per_day': newRate})
          .eq('id', vehicleId);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return;
      }
      rethrow;
    }
  }

  /// Update vehicle location hub
  Future<void> updateVehicleLocation(String vehicleId, String newLocationId) async {
    try {
      await _supabase
          .from('vehicles')
          .update({'location_id': newLocationId})
          .eq('id', vehicleId);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return;
      }
      rethrow;
    }
  }

  /// Delete a vehicle from the fleet
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _supabase
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return;
      }
      rethrow;
    }
  }

  /// Add a new location hub
  Future<Location> addLocation(Location location) async {
    try {
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
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return location;
      }
      rethrow;
    }
  }

  /// Delete a location hub
  Future<void> deleteLocation(String locationId) async {
    try {
      await _supabase
          .from('locations')
          .delete()
          .eq('id', locationId);
    } catch (e) {
      if (e.toString().contains('placeholder')) {
        return;
      }
      rethrow;
    }
  }
}

@riverpod
VehicleRepository vehicleRepository(VehicleRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return VehicleRepository(client);
}

@riverpod
Future<List<Location>> locations(LocationsRef ref) {
  return ref.watch(vehicleRepositoryProvider).fetchLocations();
}

@riverpod
Future<List<Vehicle>> vehiclesList(VehiclesListRef ref, {String? locationId}) {
  return ref.watch(vehicleRepositoryProvider).fetchVehicles(locationId: locationId);
}
