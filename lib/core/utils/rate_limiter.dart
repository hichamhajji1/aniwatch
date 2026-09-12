import 'dart:async';
import 'dart:collection';

/// Serializes work so at most [maxPerSecond] tasks start inside any 1s window.
class RateLimiter {
  RateLimiter({this.maxPerSecond = 3});

  final int maxPerSecond;
  final Queue<DateTime> _startedAt = Queue<DateTime>();
  final Queue<_QueuedJob> _pending = Queue<_QueuedJob>();
  DateTime? _lastStart;
  bool _pumping = false;

  Future<T> schedule<T>(Future<T> Function() task, {bool priority = false}) {
    final completer = Completer<T>();
    final job = _QueuedJob<T>(task, completer);
    if (priority) {
      _pending.addFirst(job);
    } else {
      _pending.add(job);
    }
    _pump();
    return completer.future;
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_pending.isNotEmpty) {
        final wait = _delayUntilSlot();
        if (wait > Duration.zero) {
          await Future<void>.delayed(wait);
        }
        if (_pending.isEmpty) break;
        final job = _pending.removeFirst();
        _startedAt.add(DateTime.now());
        _lastStart = DateTime.now();
        job.start();
      }
    } finally {
      _pumping = false;
    }
  }

  Duration _delayUntilSlot() {
    final now = DateTime.now();
    while (_startedAt.isNotEmpty && now.difference(_startedAt.first) >= const Duration(seconds: 1)) {
      _startedAt.removeFirst();
    }
    if (_startedAt.length < maxPerSecond) {
      if (_lastStart == null) return Duration.zero;
      final since = now.difference(_lastStart!);
      const minGap = Duration(milliseconds: 700);
      return since >= minGap ? Duration.zero : minGap - since;
    }
    final oldest = _startedAt.first;
    final elapsed = now.difference(oldest);
    final remaining = const Duration(seconds: 1) - elapsed;
    return remaining < Duration.zero ? Duration.zero : remaining + const Duration(milliseconds: 20);
  }
}

class _QueuedJob<T> {
  _QueuedJob(this.task, this.completer);

  final Future<T> Function() task;
  final Completer<T> completer;

  void start() {
    () async {
      try {
        final value = await task();
        if (!completer.isCompleted) completer.complete(value);
      } catch (error, stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      }
    }();
  }
}
