import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tracker_state.dart';

class TrackerCubit extends Cubit<TrackerState> {

  StreamSubscription<Position>? _gpsSubscription;
  Timer? _uiRefreshTimer;
  DateTime? _sessionStartTime;

  final double targetLat = 23.8103;
  final double targetLng = 90.4125;
  final int taskId = 42; // Example static project id injection placeholder

  TrackerCubit() : super(TrackerState.initial()) { syncSession(); }

  Future<void> syncSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedStart = prefs.getString('native_anchor_time');

    if (cachedStart != null) {
      _sessionStartTime = DateTime.parse(cachedStart);
      emit(state.copyWith(
        isRunning: true,
        startTimeMillis: _sessionStartTime!.millisecondsSinceEpoch,
      ));
      _startTrackingThreads();
    }
  }

  Future<void> toggleTracking() async {
    final prefs = await SharedPreferences.getInstance();

    if (state.isRunning) {

      Map<String, dynamic> apiPayload = prepareApiPayload(status: "COMPLETED");
      print("🚀 READY FOR API POST REQUEST: $apiPayload");

      await prefs.remove('native_anchor_time');
      _stopTrackingThreads();
      _sessionStartTime = null;
      emit(TrackerState.initial());
    }
    else {

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          emit(state.copyWith(errorMessage: "Location permissions are required."));
          return;
        }
      }

      _sessionStartTime = DateTime.now();
      await prefs.setString('native_anchor_time', _sessionStartTime!.toIso8601String());

      emit(state.copyWith(
        isRunning: true,
        startTimeMillis: _sessionStartTime!.millisecondsSinceEpoch,
        logLocations: [],
      ));
      _startTrackingThreads();
    }
  }

  void _startTrackingThreads() {

    if (_sessionStartTime == null) return;
    _stopTrackingThreads();

    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(state.copyWith(elapsedTime: DateTime.now().difference(_sessionStartTime!)));
    });

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 40, // Collects new coordinates when moving past 40 meters
        //intervalDuration: const Duration(seconds: 30), // Force a strict time configuration interval (e.g., 30 seconds)
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Work Tracker Active",
          notificationText: "Verifying your cleaning zone proximity safely.",
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          enableWakeLock: false,
        ),
      ),
    ).listen((Position position) {
      double distanceInMeters = Geolocator.distanceBetween(
          position.latitude, position.longitude, targetLat, targetLng
      );
      bool outside = distanceInMeters > 402.0;

      final newLocation = LogLocation(lat: position.latitude, lng: position.longitude);
      final updatedRouteList = List<LogLocation>.from(state.logLocations)..add(newLocation);

      emit(state.copyWith(
        isOutsideRadius: outside,
        logLocations: updatedRouteList,
      ));
    }, onError: (_) {});
  }

  // Generates structural mapping corresponding directly
  Map<String, dynamic> prepareApiPayload({required String status}) {
    return {
      "task": taskId,
      "status": status,
      "start_time": state.startTimeMillis ?? 0,
      "end_time": DateTime.now().millisecondsSinceEpoch,
      "start_attachment": "", // Add image file string pathways if required
      "end_attachment": "",
      "log_locations": state.logLocations.map((loc) => loc.toJson()).toList(),
    };
  }

  void pauseVisualTimerOnly() => _uiRefreshTimer?.cancel();

  void resumeVisualTimerOnly() {
    if (state.isRunning) _startTrackingThreads();
  }

  void _stopTrackingThreads() {
    _uiRefreshTimer?.cancel();
    _gpsSubscription?.cancel();
  }

  void clearAlert() => emit(state.copyWith(isOutsideRadius: false));

  @override
  Future<void> close() {
    _stopTrackingThreads();
    return super.close();
  }
}