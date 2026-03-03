import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_search_provider.g.dart';

class GlobalSearchState {
  final bool isActive;
  final String query;
  final bool isLoading;

  const GlobalSearchState({
    this.isActive = false,
    this.query = '',
    this.isLoading = false,
  });

  GlobalSearchState copyWith({bool? isActive, String? query, bool? isLoading}) {
    return GlobalSearchState(
      isActive: isActive ?? this.isActive,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class GlobalSearch extends _$GlobalSearch {
  @override
  GlobalSearchState build() => const GlobalSearchState();

  void activate() {
    state = state.copyWith(isActive: true);
  }

  void deactivate() {
    state = const GlobalSearchState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}
