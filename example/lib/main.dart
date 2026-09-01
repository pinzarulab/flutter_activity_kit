import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_kit/flutter_activity_kit.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const FlutterActivityKitExampleApp());
}

class FlutterActivityKitExampleApp extends StatelessWidget {
  const FlutterActivityKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ActivityKit Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF007AFF),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A84FF),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ActivityDashboardScreen(),
    );
  }
}

class ActivityDashboardScreen extends StatefulWidget {
  const ActivityDashboardScreen({super.key});

  @override
  State<ActivityDashboardScreen> createState() =>
      _ActivityDashboardScreenState();
}

class _ActivityDashboardScreenState extends State<ActivityDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isSupported = false;
  bool _areActivitiesEnabled = false;
  String? _pushToStartToken;

  // Active Sessions
  ActivitySession<MapActivityAttributes, MapActivityContentState>?
      _rideSession;
  ActivitySession<MapActivityAttributes, MapActivityContentState>?
      _deliverySession;
  ActivitySession<MapActivityAttributes, MapActivityContentState>?
      _sportsSession;

  // Reactive Controller Demo
  late final ActivityController<Map<String, dynamic>> _workoutController;

  // Ride Tracking with Mini-Map Simulation State
  int _rideStep = 0;
  Timer? _rideAutoTimer;
  bool _isRideAutoSimulating = false;

  final List<Map<String, dynamic>> _rideTimeline = [
    {
      'title': 'Driver Assigned',
      'message': 'Marco (Toyota Camry • 7XYZ99) is 6 mins away',
      'status': '6 mins 🚕',
      'progress': 0.15,
      'eta': '6 mins',
      'driverLat': '37.7710',
      'driverLng': '-122.4230',
      'destLat': '37.7849',
      'destLng': '-122.4094',
    },
    {
      'title': 'Driver Approaching',
      'message': 'Driver is 0.4 miles away on Market St',
      'status': '3 mins 🚕',
      'progress': 0.50,
      'eta': '3 mins',
      'driverLat': '37.7780',
      'driverLng': '-122.4160',
      'destLat': '37.7849',
      'destLng': '-122.4094',
    },
    {
      'title': 'Driver Arrived',
      'message': 'Marco is waiting outside at the pickup spot',
      'status': 'Arrived 📍',
      'progress': 0.85,
      'eta': 'Now',
      'driverLat': '37.7840',
      'driverLng': '-122.4100',
      'destLat': '37.7849',
      'destLng': '-122.4094',
    },
    {
      'title': 'On Trip to Destination',
      'message': 'Heading to Downtown San Francisco',
      'status': 'On Trip 🛣️',
      'progress': 1.0,
      'eta': '10 mins',
      'driverLat': '37.7849',
      'driverLng': '-122.4094',
      'destLat': '37.7849',
      'destLng': '-122.4094',
    },
  ];

  int _deliveryStep = 0;
  static const int _totalDeliverySteps = 4;

  Map<String, dynamic> _getDeliveryStepData(int step) {
    switch (step) {
      case 0:
        return {
          'title': 'Order Confirmed',
          'message': 'Bella Pizza is preparing your order',
          'progress': 0.15,
          'status': 'Preparing 🍕',
          'eta': '25 mins',
          'timer': ActivityTimer.countdown(const Duration(minutes: 25)),
        };
      case 1:
        return {
          'title': 'Baking in Oven',
          'message': 'Your artisan pizza is in the stone oven',
          'progress': 0.45,
          'status': 'Baking 🔥',
          'eta': '18 mins',
          'timer': ActivityTimer.countdown(const Duration(minutes: 18)),
        };
      case 2:
        return {
          'title': 'Out for Delivery',
          'message': 'Driver Alex is on the way (0.8 miles away)',
          'progress': 0.80,
          'status': 'On the Way 🛵',
          'eta': '5 mins',
          'timer': ActivityTimer.countdown(const Duration(minutes: 5)),
        };
      case 3:
      default:
        return {
          'title': 'Arrived',
          'message': 'Driver is at your door. Enjoy your meal!',
          'progress': 1.0,
          'status': 'Delivered 🎉',
          'eta': 'Arrived',
          'timer': null,
        };
    }
  }

  // Sports state
  int _homeScore = 2;
  int _awayScore = 1;
  int _matchMinute = 74;
  String _matchEventText = 'Live 74\' • Dangerous counter-attack';
  Timer? _sportsAutoTimer;
  bool _isAutoSimulating = false;
  int _autoSimStep = 0;

  final List<Map<String, dynamic>> _sportsMatchTimeline = [
    {
      'minute': 74,
      'home': 2,
      'away': 1,
      'status': 'Live 74\'',
      'title': 'Real Madrid vs Barcelona',
      'message': 'Real Madrid 2 - 1 Barcelona • Dangerous counter-attack',
      'alert': null,
    },
    {
      'minute': 78,
      'home': 2,
      'away': 1,
      'status': 'Live 78\'',
      'title': 'Real Madrid vs Barcelona',
      'message':
          'Real Madrid 2 - 1 Barcelona • Free kick for Barca near the box',
      'alert': null,
    },
    {
      'minute': 82,
      'home': 3,
      'away': 1,
      'status': 'GOAL! 82\'',
      'title': '⚽ GOAL! Real Madrid',
      'message': 'Bellingham scores! Real Madrid 3 - 1 Barcelona',
      'alert': const ActivityAlert(
        title: '⚽ GOAL! Real Madrid',
        body: 'Jude Bellingham makes it 3 - 1 with a stunning header!',
      ),
    },
    {
      'minute': 86,
      'home': 3,
      'away': 1,
      'status': 'Live 86\'',
      'title': 'Real Madrid vs Barcelona',
      'message': '🟨 Yellow card shown to Barcelona midfielder',
      'alert': null,
    },
    {
      'minute': 90,
      'home': 3,
      'away': 1,
      'status': 'Live 90+1\'',
      'title': 'Real Madrid vs Barcelona',
      'message': '⏱️ 4 minutes of stoppage time added',
      'alert': null,
    },
    {
      'minute': 92,
      'home': 3,
      'away': 2,
      'status': 'GOAL! 90+2\'',
      'title': '⚽ GOAL! Barcelona',
      'message': 'Lewandowski pulls one back! (3 - 2)',
      'alert': const ActivityAlert(
        title: '⚽ GOAL! Barcelona',
        body: 'Robert Lewandowski scores in stoppage time! (3 - 2)',
      ),
    },
    {
      'minute': 94,
      'home': 3,
      'away': 2,
      'status': 'FT',
      'title': '🏁 Match Ended',
      'message': 'Final Whistle: Real Madrid 3 - 2 Barcelona',
      'alert': const ActivityAlert(
        title: '🏁 Full Time',
        body: 'Final Whistle! Real Madrid wins 3 - 2 against Barcelona',
      ),
    },
  ];

  final List<String> _eventLogs = [];
  final List<void Function()> _cancelListeners = [];
  bool _isShowingMatchStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initPlatformStatus();
    _subscribeToGlobalEvents();

    _workoutController = ActivityController<Map<String, dynamic>>(
      initialState: {
        'title': 'Outdoor Run',
        'status': 'Running 🏃',
        'message': 'Pace: 5:12 min/km • Distance: 3.4 km',
        'progress': 0.45,
      },
      activityType: 'WorkoutAttributes',
      actions: const [
        ActivityAction(
            id: 'pause_workout', title: 'Pause', icon: 'ic_media_pause'),
        ActivityAction(
            id: 'finish_workout', title: 'Finish', isDestructive: true),
      ],
    );
  }

  @override
  void dispose() {
    _rideAutoTimer?.cancel();
    _sportsAutoTimer?.cancel();
    _workoutController.dispose();
    for (final cancel in _cancelListeners) {
      cancel();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initPlatformStatus() async {
    try {
      final supported = await FlutterActivityKit.isSupported();
      final enabled = await FlutterActivityKit.areActivitiesEnabled();
      final token = await FlutterActivityKit.getPushToStartToken();

      setState(() {
        _isSupported = supported;
        _areActivitiesEnabled = enabled;
        _pushToStartToken = token;
      });
    } catch (e) {
      _logEvent('Error initializing platform status: $e');
    }
  }

  void _subscribeToGlobalEvents() {
    // 🎛️ Declarative Action Routing
    _cancelListeners.add(
      FlutterActivityKit.onAnyAction((event) {
        _logEvent(
            'Action Tapped: [${event.actionId}] on activity ${event.activityId}');
      }),
    );

    _cancelListeners.add(
      FlutterActivityKit.onAction('call_driver', (event) async {
        _logEvent('Action Callback: Calling Driver via Native Phone App');
        final uri = Uri.parse('tel:+15550199');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _logEvent('Phone dialer unavailable on this device');
        }
      }),
    );

    _cancelListeners.add(
      FlutterActivityKit.onAction('match_stats', (event) {
        if (_sportsSession?.id != event.activityId) {
          _logEvent('Ignored match_stats for non-match activity');
          return;
        }
        _logEvent('Action Callback: Opening Match Stats Screen');
        _tabController.animateTo(1);
        unawaited(_showMatchStats());
      }),
    );

    _cancelListeners.add(
      FlutterActivityKit.onAction('mute_match', (event) {
        _logEvent('Action Callback: Match Muted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match notifications muted from Live Activity'),
              backgroundColor: Colors.indigo,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }),
    );

    // Push token hook
    _cancelListeners.add(
      FlutterActivityKit.onPushToken((activityId, token) {
        _logEvent(
            'Push Token Synced: ${activityId.substring(0, 8)} -> ${token.substring(0, 10)}...');
      }),
    );
  }

  Future<void> _showMatchStats() async {
    if (_isShowingMatchStats || !mounted) return;
    _isShowingMatchStats = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Live Match Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Real Madrid $_homeScore - $_awayScore Barcelona ($_matchMinute\')',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatRow('Possession', '54%', '46%'),
                    _buildStatRow('Expected Goals (xG)', '2.41', '1.87'),
                    _buildStatRow('Total Shots', '14', '11'),
                    _buildStatRow('Shots on Target', '7', '5'),
                    _buildStatRow('Corner Kicks', '6', '4'),
                    _buildStatRow('Fouls', '8', '12'),
                    _buildStatRow('Yellow Cards', '1', '2'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close Statistics'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      _isShowingMatchStats = false;
    }
  }

  Widget _buildStatRow(String title, String homeVal, String awayVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(homeVal,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(awayVal,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _logEvent(String log) {
    setState(() {
      _eventLogs.insert(
          0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $log');
      if (_eventLogs.length > 50) _eventLogs.removeLast();
    });
  }

  // --- Ride & Mini-Map Tracking Actions (Fluent Quick-Start API) ---
  Future<void> _startRideActivity({bool autoSimulate = false}) async {
    try {
      if (!_areActivitiesEnabled) {
        final granted = await FlutterActivityKit.requestPermissions();
        setState(() => _areActivitiesEnabled = granted);
      }

      _rideAutoTimer?.cancel();
      _rideStep = 0;
      final initialStep = _rideTimeline[_rideStep];

      final session = await FlutterActivityKit.start(
        activityType: 'RideAttributes',
        title: initialStep['title'] as String,
        message: initialStep['message'] as String,
        status: initialStep['status'] as String,
        progress: initialStep['progress'] as double,
        data: {
          'eta': initialStep['eta'] as String,
          'driverLat': initialStep['driverLat'] as String,
          'driverLng': initialStep['driverLng'] as String,
          'destLat': initialStep['destLat'] as String,
          'destLng': initialStep['destLng'] as String,
          'driverName': 'Marco',
          'carModel': 'Toyota Camry',
          'licensePlate': '7XYZ99',
        },
        attributes: const {
          'rideId': 'RIDE-8821',
          'driver': 'Marco',
          'vehicle': 'Toyota Camry (Silver)',
          'plate': '7XYZ99',
        },
        actions: const [
          ActivityAction(
            id: 'call_driver',
            title: 'Call Driver',
            icon: 'ic_menu_call',
          ),
          ActivityAction(
            id: 'share_eta',
            title: 'Share ETA',
            icon: 'ic_menu_share',
          ),
        ],
      );

      setState(() {
        _rideSession = session;
        _isRideAutoSimulating = autoSimulate;
      });

      _logEvent('Started Ride & Mini-Map Activity: ${session.id}');
      if (autoSimulate) {
        _startAutoRideSimulation();
      }
    } catch (e) {
      _logEvent('Error starting ride activity: $e');
    }
  }

  void _startAutoRideSimulation() {
    _rideAutoTimer?.cancel();
    _rideAutoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_rideSession == null) {
        timer.cancel();
        return;
      }
      _advanceRideTimeline();
    });
  }

  void _toggleRideAutoSimulation() {
    setState(() {
      _isRideAutoSimulating = !_isRideAutoSimulating;
      if (_isRideAutoSimulating) {
        _startAutoRideSimulation();
        _logEvent('Resumed Ride Route Auto-Simulation (every 4s)');
      } else {
        _rideAutoTimer?.cancel();
        _logEvent('Paused Ride Route Auto-Simulation');
      }
    });
  }

  Future<void> _advanceRideTimeline() async {
    if (_rideSession == null) return;
    if (_rideStep >= _rideTimeline.length - 1) {
      _rideAutoTimer?.cancel();
      setState(() => _isRideAutoSimulating = false);
      _logEvent('Ride route simulation completed');
      return;
    }

    _rideStep++;
    final step = _rideTimeline[_rideStep];
    setState(() {});

    try {
      await _rideSession!.quickUpdate(
        title: step['title'] as String,
        message: step['message'] as String,
        status: step['status'] as String,
        progress: step['progress'] as double,
        data: {
          'eta': step['eta'] as String,
          'driverLat': step['driverLat'] as String,
          'driverLng': step['driverLng'] as String,
          'destLat': step['destLat'] as String,
          'destLng': step['destLng'] as String,
        },
      );
      _logEvent('Updated Ride Location -> ${step['status']} (${step['eta']})');
    } catch (e) {
      _logEvent('Error advancing ride timeline: $e');
    }
  }

  Future<void> _endRideActivity() async {
    if (_rideSession == null) return;
    _rideAutoTimer?.cancel();
    try {
      await _rideSession!.quickEnd(
        title: 'Trip Completed',
        message: 'You have arrived at your destination.',
        status: 'Arrived 🎉',
        dismissalPolicy: ActivityDismissalPolicy.immediate,
      );
      _logEvent('Ended Ride Activity: ${_rideSession!.id}');
      setState(() {
        _rideSession = null;
        _isRideAutoSimulating = false;
      });
    } catch (e) {
      _logEvent('Error ending ride activity: $e');
    }
  }

  // --- Delivery Activity Actions (Fluent Quick-Start API) ---
  Future<void> _startDeliveryActivity() async {
    try {
      if (!_areActivitiesEnabled) {
        final granted = await FlutterActivityKit.requestPermissions();
        setState(() => _areActivitiesEnabled = granted);
      }

      _deliveryStep = 0;
      final stepData = _getDeliveryStepData(_deliveryStep);

      // 🚀 Fluent Quick-Start API: Start in 1 concise call!
      final session = await FlutterActivityKit.start(
        activityType: 'DeliveryAttributes',
        title: stepData['title'] as String,
        message: stepData['message'] as String,
        status: stepData['status'] as String,
        progress: stepData['progress'] as double,
        attributes: const {
          'orderId': 'ORD-54912',
          'restaurant': 'Bella Pizza',
          'customer': 'Daniel',
        },
        actions: const [
          ActivityAction(
            id: 'call_driver',
            title: 'Call Driver',
            icon: 'ic_menu_call',
          ),
          ActivityAction(
            id: 'cancel_order',
            title: 'Cancel',
            isDestructive: true,
          ),
        ],
      );

      setState(() {
        _deliverySession = session;
      });

      _logEvent('Started Delivery Activity: ${session.id}');
    } catch (e) {
      _logEvent('Error starting delivery activity: $e');
    }
  }

  Future<void> _nextDeliveryStep() async {
    if (_deliverySession == null) return;
    if (_deliveryStep >= _totalDeliverySteps - 1) return;

    _deliveryStep++;
    final stepData = _getDeliveryStepData(_deliveryStep);

    try {
      // ⚡ Quick Update directly on session:
      await _deliverySession!.quickUpdate(
        title: stepData['title'] as String,
        message: stepData['message'] as String,
        status: stepData['status'] as String,
        progress: stepData['progress'] as double,
      );
      setState(() {});
      _logEvent('Updated Delivery Activity -> Step ${_deliveryStep + 1}');
    } catch (e) {
      _logEvent('Error updating delivery activity: $e');
    }
  }

  Future<void> _endDeliveryActivity() async {
    if (_deliverySession == null) return;
    try {
      // 🏁 Quick End:
      await _deliverySession!.quickEnd(
        dismissalPolicy: ActivityDismissalPolicy.immediate,
      );
      _logEvent('Ended Delivery Activity: ${_deliverySession!.id}');
      setState(() {
        _deliverySession = null;
      });
    } catch (e) {
      _logEvent('Error ending delivery activity: $e');
    }
  }

  // --- Sports Match Activity Actions (Fluent Quick-Start API) ---
  Future<void> _startSportsActivity({bool autoSimulate = true}) async {
    try {
      if (!_areActivitiesEnabled) {
        final granted = await FlutterActivityKit.requestPermissions();
        setState(() => _areActivitiesEnabled = granted);
      }

      _sportsAutoTimer?.cancel();
      _autoSimStep = 0;
      final initialStep = _sportsMatchTimeline[_autoSimStep];
      _homeScore = initialStep['home'] as int;
      _awayScore = initialStep['away'] as int;
      _matchMinute = initialStep['minute'] as int;
      _matchEventText = initialStep['message'] as String;

      // 🚀 Fluent Quick-Start API:
      final session = await FlutterActivityKit.start(
        activityType: 'SportsAttributes',
        title: initialStep['title'] as String,
        message: initialStep['message'] as String,
        status: initialStep['status'] as String,
        attributes: const {
          'matchId': 'MATCH-REAL-BARCA',
          'homeTeam': 'Real Madrid',
          'awayTeam': 'Barcelona',
          'league': 'Champions League',
        },
        actions: const [
          ActivityAction(
            id: 'mute_match',
            title: 'Mute',
            icon: 'ic_lock_silent_mode',
          ),
          ActivityAction(
            id: 'match_stats',
            title: 'Stats',
            icon: 'ic_menu_info_details',
          ),
        ],
      );

      setState(() {
        _sportsSession = session;
        _isAutoSimulating = autoSimulate;
      });

      _logEvent('Started Live Sports Activity: ${session.id}');
      if (autoSimulate) {
        _startAutoSportsSimulation();
      }
    } catch (e) {
      _logEvent('Error starting sports activity: $e');
    }
  }

  void _startAutoSportsSimulation() {
    _sportsAutoTimer?.cancel();
    _sportsAutoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_sportsSession == null) {
        timer.cancel();
        return;
      }
      _advanceSportsTimeline();
    });
  }

  void _toggleSportsAutoSimulation() {
    setState(() {
      _isAutoSimulating = !_isAutoSimulating;
      if (_isAutoSimulating) {
        _startAutoSportsSimulation();
        _logEvent('Resumed Sports Auto-Simulation (every 4s)');
      } else {
        _sportsAutoTimer?.cancel();
        _logEvent('Paused Sports Auto-Simulation');
      }
    });
  }

  Future<void> _advanceSportsTimeline() async {
    if (_sportsSession == null) return;
    if (_autoSimStep >= _sportsMatchTimeline.length - 1) {
      _sportsAutoTimer?.cancel();
      setState(() => _isAutoSimulating = false);
      _logEvent('Sports match simulation reached full-time');
      return;
    }

    _autoSimStep++;
    final step = _sportsMatchTimeline[_autoSimStep];

    setState(() {
      _homeScore = step['home'] as int;
      _awayScore = step['away'] as int;
      _matchMinute = step['minute'] as int;
      _matchEventText = step['message'] as String;
    });

    try {
      await _sportsSession!.quickUpdate(
        title: step['title'] as String,
        message: step['message'] as String,
        status: step['status'] as String,
        progress: (_matchMinute / 94.0).clamp(0.0, 1.0),
        data: {
          'homeScore': _homeScore,
          'awayScore': _awayScore,
          'matchMinute': _matchMinute,
        },
        alert: step['alert'] as ActivityAlert?,
      );
      _logEvent(
          'Timeline: $_matchMinute\' (${step['status']}) - $_matchEventText');
    } catch (e) {
      _logEvent('Error advancing sports timeline: $e');
    }
  }

  Future<void> _updateSportsScore(bool homeScored) async {
    if (_sportsSession == null) return;

    setState(() {
      if (homeScored) {
        _homeScore++;
      } else {
        _awayScore++;
      }
      _matchMinute = (_matchMinute + 3).clamp(1, 90);
      _matchEventText = homeScored
          ? '⚽ GOAL! Real Madrid scores! ($_homeScore - $_awayScore)'
          : '⚽ GOAL! Barcelona scores! ($_homeScore - $_awayScore)';
    });

    try {
      await _sportsSession!.quickUpdate(
        title: 'Real Madrid vs Barcelona',
        message: 'GOAL! Score: $_homeScore - $_awayScore',
        status: 'Live $_matchMinute\'',
        progress: (_matchMinute / 90.0).clamp(0.0, 1.0),
        data: {
          'homeScore': _homeScore,
          'awayScore': _awayScore,
          'matchMinute': _matchMinute,
        },
        alert: ActivityAlert(
          title: '⚽ GOAL!',
          body: homeScored
              ? 'Real Madrid scored! ($_homeScore - $_awayScore)'
              : 'Barcelona scored! ($_homeScore - $_awayScore)',
        ),
      );
      _logEvent('Goal scored! New score: $_homeScore - $_awayScore');
    } catch (e) {
      _logEvent('Error updating sports score: $e');
    }
  }

  Future<void> _endSportsActivity() async {
    if (_sportsSession == null) return;
    _sportsAutoTimer?.cancel();
    try {
      await _sportsSession!.quickEnd(
        title: 'Match Ended',
        message: 'Full Time: Real Madrid $_homeScore - $_awayScore Barcelona',
        status: 'FT',
        progress: 1.0,
        dismissalPolicy: ActivityDismissalPolicy.defaultPolicy,
      );
      _logEvent('Ended Sports Activity: ${_sportsSession!.id}');
      setState(() {
        _sportsSession = null;
        _isAutoSimulating = false;
      });
    } catch (e) {
      _logEvent('Error ending sports activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🎛️ ActivityActionListener wraps UI for declarative action handling
    return ActivityActionListener(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Flutter ActivityKit v0.5.1'),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.local_taxi_rounded), text: 'Ride & Map'),
              Tab(icon: Icon(Icons.local_pizza_rounded), text: 'Food Delivery'),
              Tab(icon: Icon(Icons.sports_soccer_rounded), text: 'Live Sports'),
              Tab(
                  icon: Icon(Icons.sync_alt_rounded),
                  text: 'Reactive Controller'),
              Tab(icon: Icon(Icons.terminal_rounded), text: 'Events & Tokens'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildPlatformStatusBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRideTab(theme),
                  _buildDeliveryTab(theme),
                  _buildSportsTab(theme),
                  _buildReactiveControllerTab(theme),
                  _buildLogsAndTokensTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStatusBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            _isSupported ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isSupported ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSupported
                  ? (_areActivitiesEnabled
                      ? 'Live Activities & Notifications Active'
                      : 'Permission Needed')
                  : 'Live Activities Not Supported on this OS',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isSupported && !_areActivitiesEnabled)
            FilledButton.tonal(
              onPressed: () async {
                final granted = await FlutterActivityKit.requestPermissions();
                setState(() => _areActivitiesEnabled = granted);
              },
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }

  Widget _buildRideTab(ThemeData theme) {
    final isRunning = _rideSession != null;
    final currentStep = _rideTimeline[_rideStep];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live preview card with visual mini-map representation
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dynamic Island & Mini-Map Preview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRunning
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRunning ? 'MAP ON LOCK SCREEN & ISLAND' : 'STOPPED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isRunning ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DynamicIslandPreview(
                      leading: const Icon(Icons.local_taxi_rounded,
                          color: Colors.amber, size: 16),
                      trailing: Text(
                        currentStep['eta'] as String,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      title: currentStep['title'] as String,
                      subtitle: currentStep['message'] as String,
                      bottom: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            // Visual In-App Simulated Mini Map representation
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade900,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Stack(
                                children: [
                                  // Grid map background lines
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _MiniMapGridPainter(),
                                    ),
                                  ),
                                  // Route line between Driver and Destination
                                  Positioned(
                                    left: 40,
                                    top: 50,
                                    right: 40,
                                    child: Container(
                                      height: 3,
                                      color: Colors.amber.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  // Driver vehicle marker
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                    left: 40 + ((currentStep['progress'] as double) * 200).clamp(0.0, 200.0),
                                    top: 36,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.directions_car_rounded,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  // Destination marker
                                  const Positioned(
                                    right: 36,
                                    top: 36,
                                    child: CircleAvatar(
                                      radius: 13,
                                      backgroundColor: Colors.blue,
                                      child: Icon(Icons.home_rounded,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Driver GPS: ${currentStep['driverLat']}, ${currentStep['driverLng']}',
                                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Driver & Vehicle info card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marco (4.95 ⭐ • 2,410 trips)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Toyota Camry • Silver • 7XYZ99',
                              style: TextStyle(color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentStep['eta'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Controls Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Route Simulation & Live Mini-Map',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: currentStep['progress'] as double,
                    color: Colors.amber,
                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  if (!isRunning)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade700),
                      onPressed: () => _startRideActivity(autoSimulate: false),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Ride Activity (with Live Mini-Map)'),
                    )
                  else ...[
                    FilledButton.tonalIcon(
                      onPressed: _advanceRideTimeline,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text('Advance Route Waypoint (${_rideStep + 1}/${_rideTimeline.length})'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _toggleRideAutoSimulation,
                      icon: Icon(_isRideAutoSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isRideAutoSimulating ? 'Pause Route GPS Updates' : 'Auto-Simulate GPS (every 4s)'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: _endRideActivity,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('End Ride Activity'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab(ThemeData theme) {
    final isRunning = _deliverySession != null;
    final currentStepData = _getDeliveryStepData(_deliveryStep);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live preview card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dynamic Island / Notification Preview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRunning
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRunning ? 'RUNNING (OS-RENDERED)' : 'STOPPED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isRunning ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DynamicIslandPreview(
                      leading: const Icon(Icons.local_pizza,
                          color: Colors.orange, size: 16),
                      trailing: Text(
                        currentStepData['eta'] as String,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      title: currentStepData['title'] as String,
                      subtitle: currentStepData['message'] as String,
                      bottom: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: currentStepData['progress'] as double,
                          color: Colors.orange,
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Order Stage Pipeline',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: currentStepData['progress'] as double,
                    color: Colors.orange,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  if (!isRunning)
                    FilledButton.icon(
                      onPressed: _startDeliveryActivity,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label:
                          const Text('Start Order Live Activity (Fluent API)'),
                    )
                  else ...[
                    FilledButton.tonalIcon(
                      onPressed: _nextDeliveryStep,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(
                          'Advance to Next Stage (${_deliveryStep + 1}/$_totalDeliverySteps)'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: _endDeliveryActivity,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('End Order Activity'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsTab(ThemeData theme) {
    final isRunning = _sportsSession != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live scoreboard card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Match Scoreboard',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRunning
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isRunning ? 'MATCH LIVE' : 'STOPPED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRunning ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.shield_rounded,
                              size: 36, color: Colors.blue),
                          const SizedBox(height: 4),
                          const Text('Real Madrid',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$_homeScore',
                              style: theme.textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Live $_matchMinute\'',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 4),
                          const Text('VS',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.shield_rounded,
                              size: 36, color: Colors.red),
                          const SizedBox(height: 4),
                          const Text('Barcelona',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$_awayScore',
                              style: theme.textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _matchEventText,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Match Controls',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isRunning)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isAutoSimulating
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAutoSimulating
                                    ? Icons.timer_outlined
                                    : Icons.pause_circle_outline,
                                size: 12,
                                color: _isAutoSimulating
                                    ? Colors.green
                                    : Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAutoSimulating
                                    ? 'Auto (4s ticks)'
                                    : 'Paused',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isAutoSimulating
                                      ? Colors.green
                                      : Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isRunning) ...[
                    FilledButton.icon(
                      onPressed: () => _startSportsActivity(autoSimulate: true),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label:
                          const Text('Start Auto-Simulated Match (4s Ticks)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _startSportsActivity(autoSimulate: false),
                      icon: const Icon(Icons.touch_app_rounded),
                      label: const Text('Start Manual Match'),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _toggleSportsAutoSimulation,
                            icon: Icon(_isAutoSimulating
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                            label: Text(_isAutoSimulating
                                ? 'Pause Auto'
                                : 'Resume Auto'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _advanceSportsTimeline,
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('Next Minute'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => _updateSportsScore(true),
                            child: const Text('Goal Madrid (+1)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => _updateSportsScore(false),
                            child: const Text('Goal Barca (+1)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: _endSportsActivity,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('End Match Activity'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactiveControllerTab(ThemeData theme) {
    return ActivityBuilder<Map<String, dynamic>>(
      controller: _workoutController,
      builder: (context, state, isActive, child) {
        final progress = (state['progress'] as num?)?.toDouble() ?? 0.0;
        final status = state['status'] as String? ?? 'Ready';
        final message = state['message'] as String? ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reactive ActivityController<T>',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'IDLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Status: $status',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(message,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mutate State (Auto-Syncs Live Activity)',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text('Progress Slider: ${(progress * 100).toInt()}%'),
                      Slider(
                        value: progress,
                        onChanged: (val) {
                          _workoutController.value = {
                            ...state,
                            'progress': val,
                            'message':
                                'Distance: ${(val * 8.0).toStringAsFixed(1)} km',
                          };
                        },
                        onChangeEnd: (_) {
                          _workoutController.syncImmediately();
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('🏃 Running'),
                            onPressed: () {
                              _workoutController.updateState({
                                ...state,
                                'status': 'Running 🏃',
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('🚴 Cycling'),
                            onPressed: () {
                              _workoutController.updateState({
                                ...state,
                                'status': 'Cycling 🚴',
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('⏸️ Paused'),
                            onPressed: () {
                              _workoutController.updateState({
                                ...state,
                                'status': 'Paused ⏸️',
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!isActive)
                        FilledButton.icon(
                          onPressed: () => _workoutController.start(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Workout Activity'),
                        )
                      else
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          onPressed: () => _workoutController.end(
                            finalState: {
                              ...state,
                              'status': 'Workout Completed! 🏆',
                              'progress': 1.0,
                            },
                          ),
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('End Workout Activity'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsAndTokensTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Push-to-Start Token Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Push-to-Start Token (iOS 17.2+)',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: _pushToStartToken != null
                            ? () {
                                Clipboard.setData(
                                    ClipboardData(text: _pushToStartToken!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Push-to-start token copied to clipboard')),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pushToStartToken ??
                        'Not generated (Available on physical iOS 17.2+ device)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace', color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Event Logs Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Event Stream',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _eventLogs.clear()),
                child: const Text('Clear'),
              ),
            ],
          ),

          // Log List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: _eventLogs.isEmpty
                  ? const Center(
                      child: Text('No events yet. Start an activity above.'))
                  : ListView.builder(
                      itemCount: _eventLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _eventLogs[index],
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
