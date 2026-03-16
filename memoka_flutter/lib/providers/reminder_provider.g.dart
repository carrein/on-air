// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the Reminder state for a specific note.
/// Returns null when the note has no reminder.

@ProviderFor(ReminderNotifier)
final reminderProvider = ReminderNotifierFamily._();

/// Provides the Reminder state for a specific note.
/// Returns null when the note has no reminder.
final class ReminderNotifierProvider
    extends $AsyncNotifierProvider<ReminderNotifier, Reminder?> {
  /// Provides the Reminder state for a specific note.
  /// Returns null when the note has no reminder.
  ReminderNotifierProvider._({
    required ReminderNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'reminderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reminderNotifierHash();

  @override
  String toString() {
    return r'reminderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReminderNotifier create() => ReminderNotifier();

  @override
  bool operator ==(Object other) {
    return other is ReminderNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reminderNotifierHash() => r'ea0880957df2993a4044c22eed63a885d2f35eb2';

/// Provides the Reminder state for a specific note.
/// Returns null when the note has no reminder.

final class ReminderNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ReminderNotifier,
          AsyncValue<Reminder?>,
          Reminder?,
          FutureOr<Reminder?>,
          int
        > {
  ReminderNotifierFamily._()
    : super(
        retry: null,
        name: r'reminderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the Reminder state for a specific note.
  /// Returns null when the note has no reminder.

  ReminderNotifierProvider call(int noteId) =>
      ReminderNotifierProvider._(argument: noteId, from: this);

  @override
  String toString() => r'reminderProvider';
}

/// Provides the Reminder state for a specific note.
/// Returns null when the note has no reminder.

abstract class _$ReminderNotifier extends $AsyncNotifier<Reminder?> {
  late final _$args = ref.$arg as int;
  int get noteId => _$args;

  FutureOr<Reminder?> build(int noteId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Reminder?>, Reminder?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Reminder?>, Reminder?>,
              AsyncValue<Reminder?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
