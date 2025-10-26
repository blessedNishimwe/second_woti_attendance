import 'dart:async';
import 'package:flutter/foundation.dart';

/// High-performance timer service that minimizes rebuilds
class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  bool _isRunning = false;
  
  // Listeners for different update intervals
  final Map<String, TimerCallback> _listeners = {};
  final Map<String, Duration> _intervals = {};

  DateTime get currentTime => _currentTime;

  /// Start the timer service
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      _notifyListeners();
    });
  }

  /// Stop the timer service
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _listeners.clear();
    _intervals.clear();
  }

  /// Add a listener with custom update interval
  void addListener(String key, TimerCallback callback, Duration interval) {
    _listeners[key] = callback;
    _intervals[key] = interval;
  }

  /// Remove a listener
  void removeListener(String key) {
    _listeners.remove(key);
    _intervals.remove(key);
  }

  void _notifyListeners() {
    // Notify main listeners (every second)
    notifyListeners();
    
    // Notify custom interval listeners
    for (final entry in _listeners.entries) {
      final key = entry.key;
      final callback = entry.value;
      final interval = _intervals[key];
      
      if (interval != null) {
        // Check if it's time to notify this listener
        final now = DateTime.now();
        final lastUpdate = _getLastUpdateTime(key);
        
        if (now.difference(lastUpdate) >= interval) {
          callback(now);
          _setLastUpdateTime(key, now);
        }
      }
    }
  }

  final Map<String, DateTime> _lastUpdateTimes = {};
  
  DateTime _getLastUpdateTime(String key) {
    return _lastUpdateTimes[key] ?? DateTime.now().subtract(const Duration(hours: 1));
  }
  
  void _setLastUpdateTime(String key, DateTime time) {
    _lastUpdateTimes[key] = time;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

typedef TimerCallback = void Function(DateTime time);

/// Optimized clock widget that only rebuilds when necessary
class OptimizedClock extends StatefulWidget {
  final TextStyle? style;
  final String Function(DateTime) formatter;
  final Duration updateInterval;

  const OptimizedClock({
    Key? key,
    this.style,
    required this.formatter,
    this.updateInterval = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  State<OptimizedClock> createState() => _OptimizedClockState();
}

class _OptimizedClockState extends State<OptimizedClock> {
  late String _displayTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.updateInterval, (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final newTime = widget.formatter(DateTime.now());
    if (newTime != _displayTime) {
      setState(() {
        _displayTime = newTime;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayTime,
      style: widget.style,
    );
  }
}
