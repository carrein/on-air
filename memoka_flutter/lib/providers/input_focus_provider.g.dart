// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_focus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InputFocusRequest)
final inputFocusRequestProvider = InputFocusRequestProvider._();

final class InputFocusRequestProvider
    extends $NotifierProvider<InputFocusRequest, bool> {
  InputFocusRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inputFocusRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inputFocusRequestHash();

  @$internal
  @override
  InputFocusRequest create() => InputFocusRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$inputFocusRequestHash() => r'b37fe6cac8790a1c6680e8665a2a9c8d8d5eff18';

abstract class _$InputFocusRequest extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
