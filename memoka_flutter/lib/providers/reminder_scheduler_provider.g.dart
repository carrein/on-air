// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Client-side timer orchestration for precise reminder delivery.
///
/// - **Web**: Uses a Web Worker (`reminder_worker.js`) whose timers are NOT
///   throttled in background tabs.
/// - **Android**: Uses `zonedSchedule` (OS alarm system) which survives app
///   kill, background, and phone reboot.
///
/// Tracks `_firedLocally` to deduplicate with WebSocket backup delivery.

@ProviderFor(ReminderScheduler)
final reminderSchedulerProvider = ReminderSchedulerProvider._();

/// Client-side timer orchestration for precise reminder delivery.
///
/// - **Web**: Uses a Web Worker (`reminder_worker.js`) whose timers are NOT
///   throttled in background tabs.
/// - **Android**: Uses `zonedSchedule` (OS alarm system) which survives app
///   kill, background, and phone reboot.
///
/// Tracks `_firedLocally` to deduplicate with WebSocket backup delivery.
final class ReminderSchedulerProvider
    extends $NotifierProvider<ReminderScheduler, void> {
  /// Client-side timer orchestration for precise reminder delivery.
  ///
  /// - **Web**: Uses a Web Worker (`reminder_worker.js`) whose timers are NOT
  ///   throttled in background tabs.
  /// - **Android**: Uses `zonedSchedule` (OS alarm system) which survives app
  ///   kill, background, and phone reboot.
  ///
  /// Tracks `_firedLocally` to deduplicate with WebSocket backup delivery.
  ReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSchedulerHash();

  @$internal
  @override
  ReminderScheduler create() => ReminderScheduler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderSchedulerHash() => r'3a2c7be2d1229f1009e8360c847b3955a14c2d56';

/// Client-side timer orchestration for precise reminder delivery.
///
/// - **Web**: Uses a Web Worker (`reminder_worker.js`) whose timers are NOT
///   throttled in background tabs.
/// - **Android**: Uses `zonedSchedule` (OS alarm system) which survives app
///   kill, background, and phone reboot.
///
/// Tracks `_firedLocally` to deduplicate with WebSocket backup delivery.

abstract class _$ReminderScheduler extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
