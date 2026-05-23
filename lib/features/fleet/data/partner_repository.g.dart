// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$partnerRepositoryHash() => r'0f8cb1b91d92c234baf988fe7a538ca5e38196ea';

/// See also [partnerRepository].
@ProviderFor(partnerRepository)
final partnerRepositoryProvider =
    AutoDisposeProvider<PartnerRepository>.internal(
  partnerRepository,
  name: r'partnerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$partnerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PartnerRepositoryRef = AutoDisposeProviderRef<PartnerRepository>;
String _$partnerApplicationsListHash() =>
    r'3e6a66fa239dc0186ffc014d247614ab3380b5b2';

/// See also [partnerApplicationsList].
@ProviderFor(partnerApplicationsList)
final partnerApplicationsListProvider =
    AutoDisposeFutureProvider<List<PartnerApplication>>.internal(
  partnerApplicationsList,
  name: r'partnerApplicationsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$partnerApplicationsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PartnerApplicationsListRef
    = AutoDisposeFutureProviderRef<List<PartnerApplication>>;
String _$partnersListHash() => r'392b3234b285eb851f4d1414cf62ce4564f21a2c';

/// See also [partnersList].
@ProviderFor(partnersList)
final partnersListProvider = AutoDisposeFutureProvider<List<Partner>>.internal(
  partnersList,
  name: r'partnersListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$partnersListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PartnersListRef = AutoDisposeFutureProviderRef<List<Partner>>;
String _$partnerDetailsHash() => r'5b4f9783bc80b7f982f6ac8321ee8411ec0b3a7f';

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

/// See also [partnerDetails].
@ProviderFor(partnerDetails)
const partnerDetailsProvider = PartnerDetailsFamily();

/// See also [partnerDetails].
class PartnerDetailsFamily extends Family<AsyncValue<Partner?>> {
  /// See also [partnerDetails].
  const PartnerDetailsFamily();

  /// See also [partnerDetails].
  PartnerDetailsProvider call(
    String id,
  ) {
    return PartnerDetailsProvider(
      id,
    );
  }

  @override
  PartnerDetailsProvider getProviderOverride(
    covariant PartnerDetailsProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'partnerDetailsProvider';
}

/// See also [partnerDetails].
class PartnerDetailsProvider extends AutoDisposeFutureProvider<Partner?> {
  /// See also [partnerDetails].
  PartnerDetailsProvider(
    String id,
  ) : this._internal(
          (ref) => partnerDetails(
            ref as PartnerDetailsRef,
            id,
          ),
          from: partnerDetailsProvider,
          name: r'partnerDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$partnerDetailsHash,
          dependencies: PartnerDetailsFamily._dependencies,
          allTransitiveDependencies:
              PartnerDetailsFamily._allTransitiveDependencies,
          id: id,
        );

  PartnerDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Partner?> Function(PartnerDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PartnerDetailsProvider._internal(
        (ref) => create(ref as PartnerDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Partner?> createElement() {
    return _PartnerDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerDetailsProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PartnerDetailsRef on AutoDisposeFutureProviderRef<Partner?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PartnerDetailsProviderElement
    extends AutoDisposeFutureProviderElement<Partner?> with PartnerDetailsRef {
  _PartnerDetailsProviderElement(super.provider);

  @override
  String get id => (origin as PartnerDetailsProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
