// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vehicleRepositoryHash() => r'1b2c2ae80fe8656b44f31f9f8ebf85444a7dcc92';

/// See also [vehicleRepository].
@ProviderFor(vehicleRepository)
final vehicleRepositoryProvider =
    AutoDisposeProvider<VehicleRepository>.internal(
  vehicleRepository,
  name: r'vehicleRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vehicleRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VehicleRepositoryRef = AutoDisposeProviderRef<VehicleRepository>;
String _$locationsHash() => r'5c320123d0befcbd9322507c48af919972f7aac8';

/// See also [locations].
@ProviderFor(locations)
final locationsProvider = FutureProvider<List<Location>>.internal(
  locations,
  name: r'locationsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$locationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LocationsRef = FutureProviderRef<List<Location>>;
String _$vehiclesListHash() => r'540139f277a4a0e499e3ef31317084857765f664';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [vehiclesList].
@ProviderFor(vehiclesList)
const vehiclesListProvider = VehiclesListFamily();

/// See also [vehiclesList].
class VehiclesListFamily extends Family<AsyncValue<List<Vehicle>>> {
  /// See also [vehiclesList].
  const VehiclesListFamily();

  /// See also [vehiclesList].
  VehiclesListProvider call({
    String? locationId,
  }) {
    return VehiclesListProvider(
      locationId: locationId,
    );
  }

  @override
  VehiclesListProvider getProviderOverride(
    covariant VehiclesListProvider provider,
  ) {
    return call(
      locationId: provider.locationId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vehiclesListProvider';
}

/// See also [vehiclesList].
class VehiclesListProvider extends FutureProvider<List<Vehicle>> {
  /// See also [vehiclesList].
  VehiclesListProvider({
    String? locationId,
  }) : this._internal(
          (ref) => vehiclesList(
            ref as VehiclesListRef,
            locationId: locationId,
          ),
          from: vehiclesListProvider,
          name: r'vehiclesListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vehiclesListHash,
          dependencies: VehiclesListFamily._dependencies,
          allTransitiveDependencies:
              VehiclesListFamily._allTransitiveDependencies,
          locationId: locationId,
        );

  VehiclesListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.locationId,
  }) : super.internal();

  final String? locationId;

  @override
  Override overrideWith(
    FutureOr<List<Vehicle>> Function(VehiclesListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VehiclesListProvider._internal(
        (ref) => create(ref as VehiclesListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        locationId: locationId,
      ),
    );
  }

  @override
  FutureProviderElement<List<Vehicle>> createElement() {
    return _VehiclesListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VehiclesListProvider && other.locationId == locationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, locationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VehiclesListRef on FutureProviderRef<List<Vehicle>> {
  /// The parameter `locationId` of this provider.
  String? get locationId;
}

class _VehiclesListProviderElement extends FutureProviderElement<List<Vehicle>>
    with VehiclesListRef {
  _VehiclesListProviderElement(super.provider);

  @override
  String? get locationId => (origin as VehiclesListProvider).locationId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
