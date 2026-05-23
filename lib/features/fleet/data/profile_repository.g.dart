// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'53d05f00f9bcc1cfed511012e52750df906184fc';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider =
    AutoDisposeProvider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfileRepositoryRef = AutoDisposeProviderRef<ProfileRepository>;
String _$profilesListHash() => r'62571fc4eefdb1d7c17dfdeda679274b1853408c';

/// See also [profilesList].
@ProviderFor(profilesList)
final profilesListProvider = AutoDisposeFutureProvider<List<Profile>>.internal(
  profilesList,
  name: r'profilesListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profilesListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfilesListRef = AutoDisposeFutureProviderRef<List<Profile>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
