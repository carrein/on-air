import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

web.Worker? _worker;
void Function(int noteId)? _onFired;

void initWorker(void Function(int noteId) onFired) {
  _onFired = onFired;
  _worker = web.Worker('reminder_worker.js'.toJS);
  _worker!.onmessage = (web.MessageEvent event) {
    final data = event.data as JSObject;
    final type = (data.getProperty('type'.toJS) as JSString).toDart;
    if (type == 'fired') {
      final noteId = (data.getProperty('noteId'.toJS) as JSNumber).toDartInt;
      _onFired?.call(noteId);
    }
  }.toJS;
}

void scheduleWorkerTimer(int noteId, int fireInMs) {
  _worker?.postMessage(
    {'type': 'schedule', 'noteId': noteId, 'fireInMs': fireInMs}.jsify(),
  );
}

void cancelWorkerTimer(int noteId) {
  _worker?.postMessage({'type': 'cancel', 'noteId': noteId}.jsify());
}

void cancelAllWorkerTimers() {
  _worker?.postMessage({'type': 'cancelAll'}.jsify());
}

void disposeWorker() {
  cancelAllWorkerTimers();
  _worker?.terminate();
  _worker = null;
}
