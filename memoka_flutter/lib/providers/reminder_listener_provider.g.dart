// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_listener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Listens to the WebSocket stream for reminder events and fires
/// local notifications + invalidates reminder providers.
///
/// On reconnect, pulls all fired reminders to catch any missed while offline.
/// Deduplicates with client-side scheduler fires via `_firedLocally`.

@ProviderFor(reminderListener)
final reminderListenerProvider = ReminderListenerProvider._();

/// Listens to the WebSocket stream for reminder events and fires
/// local notifications + invalidates reminder providers.
///
/// On reconnect, pulls all fired reminders to catch any missed while offline.
/// Deduplicates with client-side scheduler fires via `_firedLocally`.

final class ReminderListenerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Listens to the WebSocket stream for reminder events and fires
  /// local notifications + invalidates reminder providers.
  ///
  /// On reconnect, pulls all fired reminders to catch any missed while offline.
  /// Deduplicates with client-side scheduler fires via `_firedLocally`.
  ReminderListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderListenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return reminderListener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderListenerHash() => r'9e00870484641de9882ca7c08046cdc30a85c052';
