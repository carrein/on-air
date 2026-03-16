/// Native stub — Web Worker is web-only. Timer scheduling on native uses
/// `zonedSchedule` via `notification_service_stub.dart` instead.
void initWorker(void Function(int noteId) onFired) {}
void scheduleWorkerTimer(int noteId, int fireInMs) {}
void cancelWorkerTimer(int noteId) {}
void cancelAllWorkerTimers() {}
void disposeWorker() {}
