// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalSearch)
final globalSearchProvider = GlobalSearchProvider._();

final class GlobalSearchProvider
    extends $NotifierProvider<GlobalSearch, GlobalSearchState> {
  GlobalSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalSearchHash();

  @$internal
  @override
  GlobalSearch create() => GlobalSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalSearchState>(value),
    );
  }
}

String _$globalSearchHash() => r'd90d91b87dcbc1d68279f223abff8e5f2c1506f2';

abstract class _$GlobalSearch extends $Notifier<GlobalSearchState> {
  GlobalSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GlobalSearchState, GlobalSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GlobalSearchState, GlobalSearchState>,
              GlobalSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
