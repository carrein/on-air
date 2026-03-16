// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides all reminders for a channel (for MediaPanel Reminders tab).

@ProviderFor(channelReminders)
final channelRemindersProvider = ChannelRemindersFamily._();

/// Provides all reminders for a channel (for MediaPanel Reminders tab).

final class ChannelRemindersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reminder>>,
          List<Reminder>,
          FutureOr<List<Reminder>>
        >
    with $FutureModifier<List<Reminder>>, $FutureProvider<List<Reminder>> {
  /// Provides all reminders for a channel (for MediaPanel Reminders tab).
  ChannelRemindersProvider._({
    required ChannelRemindersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'channelRemindersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelRemindersHash();

  @override
  String toString() {
    return r'channelRemindersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Reminder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Reminder>> create(Ref ref) {
    final argument = this.argument as int;
    return channelReminders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelRemindersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelRemindersHash() => r'70eaef1a7400e40d350432072c8de2a7f535284b';

/// Provides all reminders for a channel (for MediaPanel Reminders tab).

final class ChannelRemindersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Reminder>>, int> {
  ChannelRemindersFamily._()
    : super(
        retry: null,
        name: r'channelRemindersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides all reminders for a channel (for MediaPanel Reminders tab).

  ChannelRemindersProvider call(int channelId) =>
      ChannelRemindersProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelRemindersProvider';
}
