// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.

@ProviderFor(CurrentChannel)
final currentChannelProvider = CurrentChannelProvider._();

/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.
final class CurrentChannelProvider
    extends $AsyncNotifierProvider<CurrentChannel, int> {
  /// Manages the currently active channel ID.
  /// Persists to shared preferences for restoration on app restart.
  CurrentChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentChannelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentChannelHash();

  @$internal
  @override
  CurrentChannel create() => CurrentChannel();
}

String _$currentChannelHash() => r'87e9a17439256235a73f914d8b690c94bdb3f968';

/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.

abstract class _$CurrentChannel extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
