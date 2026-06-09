class LogLocation {
  final double lat;
  final double lng;

  const LogLocation({required this.lat, required this.lng});

  // Converts data object instance directly to a standard JSON map payload
  Map<String, double> toJson() => {
    'lat': lat,
    'lng': lng,
  };
}

class TrackerState {
  final bool isRunning;
  final Duration elapsedTime;
  final bool isOutsideRadius;
  final String? errorMessage;
  final List<LogLocation> logLocations;
  final int? startTimeMillis;

  const TrackerState({
    required this.isRunning,
    required this.elapsedTime,
    required this.isOutsideRadius,
    required this.logLocations,
    this.startTimeMillis,
    this.errorMessage,
  });

  factory TrackerState.initial() => const TrackerState(
    isRunning: false,
    elapsedTime: Duration.zero,
    isOutsideRadius: false,
    logLocations: [],
    startTimeMillis: null,
    errorMessage: null,
  );

  TrackerState copyWith({
    bool? isRunning,
    Duration? elapsedTime,
    bool? isOutsideRadius,
    List<LogLocation>? logLocations,
    int? startTimeMillis,
    String? errorMessage,
  }) {
    return TrackerState(
      isRunning: isRunning ?? this.isRunning,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isOutsideRadius: isOutsideRadius ?? this.isOutsideRadius,
      logLocations: logLocations ?? this.logLocations,
      startTimeMillis: startTimeMillis ?? this.startTimeMillis,
      errorMessage: errorMessage,
    );
  }
}