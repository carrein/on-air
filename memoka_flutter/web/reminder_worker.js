// Web Worker for precise reminder timer scheduling.
// Main thread posts schedule/cancel messages; worker posts fired messages back.
// Web Worker timers are NOT throttled in background tabs.
const timers = {};
self.onmessage = (e) => {
  const { type, noteId, fireInMs } = e.data;
  if (type === 'schedule') {
    if (timers[noteId]) clearTimeout(timers[noteId]);
    timers[noteId] = setTimeout(() => {
      delete timers[noteId];
      self.postMessage({ type: 'fired', noteId });
    }, Math.max(0, fireInMs));
  } else if (type === 'cancel') {
    if (timers[noteId]) { clearTimeout(timers[noteId]); delete timers[noteId]; }
  } else if (type === 'cancelAll') {
    Object.values(timers).forEach(clearTimeout);
    for (const k in timers) delete timers[k];
  }
};
