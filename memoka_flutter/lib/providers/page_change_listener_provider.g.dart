// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_change_listener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Listens to the WebSocket stream for page watch events and fires
/// local notifications + invalidates watch providers.

@ProviderFor(pageChangeListener)
final pageChangeListenerProvider = PageChangeListenerProvider._();

/// Listens to the WebSocket stream for page watch events and fires
/// local notifications + invalidates watch providers.

final class PageChangeListenerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Listens to the WebSocket stream for page watch events and fires
  /// local notifications + invalidates watch providers.
  PageChangeListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageChangeListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageChangeListenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return pageChangeListener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pageChangeListenerHash() =>
    r'355273e9cd38bc45ccee895ee6b86bbfe839ac85';
