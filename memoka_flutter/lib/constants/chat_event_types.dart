/// String constants for WebSocket chat event types.
///
/// Centralises the magic strings so typos are caught at compile time.
abstract final class ChatEventTypes {
  static const channelCreated = 'channelCreated';
  static const channelUpdated = 'channelUpdated';
  static const channelDeleted = 'channelDeleted';
  static const channelArchived = 'channelArchived';
  static const channelRestored = 'channelRestored';
  static const noteCreated = 'noteCreated';
  static const noteUpdated = 'noteUpdated';
  static const noteDeleted = 'noteDeleted';
  static const noteArchived = 'noteArchived';
  static const noteRestored = 'noteRestored';
  static const noteLinkPreviewReady = 'noteLinkPreviewReady';
  static const pageChanged = 'pageChanged';
  static const pageWatchDisabled = 'pageWatchDisabled';
  static const reminderDue = 'reminderDue';
  static const reminderCreated = 'reminderCreated';
  static const reminderDeleted = 'reminderDeleted';
}
