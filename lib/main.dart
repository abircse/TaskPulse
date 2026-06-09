import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tracker_cubit.dart';
import 'tracker_state.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => TrackerCubit(),
        child: const TrackerScreen(),
      ),
    );
  }
}

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

// WidgetsBindingObserver catches when the user minimizes or opens the app
class _TrackerScreenState extends State<TrackerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Tell OS to watch lifecycle transitions
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<TrackerCubit>();
    if (state == AppLifecycleState.paused) {
      // User minimized the app: Kill UI updates immediately to conserve battery
      cubit.pauseVisualTimerOnly();
    } else if (state == AppLifecycleState.resumed) {
      // User opened the app back up: Re-sync clock with time anchor instantly
      cubit.resumeVisualTimerOnly();
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrackerCubit>();

    return Scaffold(
      backgroundColor: const Color(0xFFEBF7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Work Tracker", style: TextStyle(color: Color(0xFF00669E), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<TrackerCubit, TrackerState>(
        listener: (context, state) {
          if (state.isOutsideRadius) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Warning: Out of Project Area!"), backgroundColor: Colors.red),
            );
            cubit.clearAlert();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              const SizedBox(height: 30),
              const Text("Task: Qurbani Waste Cleaning", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),

              // Text timer read-out
              Text(
                _format(state.elapsedTime),
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, letterSpacing: 1.2),
              ),

              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.isRunning ? "Tracking Shield On" : "System Idling", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Optimized Low-Power Mode", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),

                    // Secure Long Press Interaction to prevent pocket false-triggers
                    GestureDetector(
                      onLongPress: () {
                        cubit.toggleTracking();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tracking updated via secure long-press interaction.")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF005596)),
                        child: Icon(state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}