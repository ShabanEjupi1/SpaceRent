import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

/// Global language state provider — defaults to English
final localeProvider = StateProvider<String>((ref) => 'en');

/// Convenience helper: reads the current locale and translates a key.
/// Usage in a ConsumerWidget: `tr('dashboard_title', ref)`
String tr(String key, WidgetRef ref) {
  final lang = ref.watch(localeProvider);
  return AppStrings.tr(key, lang);
}
