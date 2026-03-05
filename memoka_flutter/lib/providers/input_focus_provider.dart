import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'input_focus_provider.g.dart';

@riverpod
class InputFocusRequest extends _$InputFocusRequest {
  @override
  bool build() => false;
  void request() => state = true;
  void consume() => state = false;
}
