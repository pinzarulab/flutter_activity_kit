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
      _deliverySession;
  ActivitySession<MapActivityAttributes, MapActivityContentState>?
      _sportsSession;

  int _deliveryStep = 0;
  final List<Map<String, dynamic>> _deliverySteps = [
    {
      'title': 'Order Confirmed',
      'message': 'Bella Pizza is preparing your order',
      'progress': 0.15,
      'status': 'Preparing 🍕',
      'eta': '25 mins',
      'timer': ActivityTimer.countdown(const Duration(minutes: 25)),
    },
    {
      'title': 'Baking in Oven',
      'message': 'Your artisan pizza is in the stone oven',
      'progress': 0.45,
      'status': 'Baking 🔥',
      'eta': '18 mins',
      'timer': ActivityTimer.countdown(const Duration(minutes: 18)),
    },
    {
      'title': 'Out for Delivery',
      'message': 'Driver Alex is on the way (0.8 miles away)',
      'progress': 0.80,
      'status': 'On the Way 🛵',
      'eta': '5 mins',
      'timer': ActivityTimer.countdown(const Duration(minutes: 5)),
    },
    {
      'title': 'Arrived',
      'message': 'Driver is at your door. Enjoy your meal!',
      'progress': 1.0,
      'status': 'Delivered 🎉',
      'eta': 'Arrived',
    },
  ];

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
      'message': 'Real Madrid 2 - 1 Barcelona • Free kick for Barca near the box',
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
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initPlatformStatus();
    _subscribeToGlobalEvents();
  }

  @override
  void dispose() {
    _sportsAutoTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
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
    // Action events
    _subscriptions.add(
      FlutterActivityKit.actionEvents.listen((event) {
        _logEvent('Action Tapped: [${event.actionId}] on activity ${event.activityId}');
        _handleActionTap(event.actionId);
      }),
    );

    // State events
    _subscriptions.add(
      FlutterActivityKit.activityStateUpdates.listen((event) {
        _logEvent('Activity State: ${event.activityId} -> ${event.state.name}');
      }),
    );

    // Push tokens
    _subscriptions.add(
      FlutterActivityKit.pushTokenUpdates.listen((event) {
        _logEvent('Push Token: ${event.activityId} -> ${event.pushToken.substring(0, 10)}...');
      }),
    );
  }

  void _handleActionTap(String actionId) {
    switch (actionId) {
      case 'mute_match':
        _logEvent('Interactive Action: Match Alerts Muted/Unmuted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.volume_off_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Match notifications muted from Dynamic Island'),
              ],
            ),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 2),
          ),
        );
        break;

      case 'match_stats':
        _logEvent('Interactive Action: Opening Match Stats Screen');
        _tabController.animateTo(1);
        _showMatchStats();
        break;

      case 'call_driver':
        _logEvent('Interactive Action: Opening Phone App with Driver Number (+1 555-0199)');
        _openPhoneDialer('+15550199');
        break;

      case 'add_tip':
        _logEvent('Interactive Action: Added \$2 Tip for Driver');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.volunteer_activism_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Added \$2.00 tip for your driver. Thank you!'),
              ],
            ),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 2),
          ),
        );
        break;

      case 'cancel_order':
        _logEvent('Interactive Action: Order Cancellation requested');
        _endDeliveryActivity();
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Received Dynamic Island Action: $actionId'),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _openPhoneDialer(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling $phoneNumber...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _logEvent('Error launching phone app: $e');
    }
  }

  void _showMatchStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Match Statistics',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Possession', '58%', '42%'),
            _buildStatRow('Shots on Target', '7', '4'),
            _buildStatRow('Fouls', '8', '11'),
            _buildStatRow('Corner Kicks', '5', '3'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String homeVal, String awayVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(homeVal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(awayVal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _logEvent(String log) {
    setState(() {
      _eventLogs.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $log');
      if (_eventLogs.length > 50) _eventLogs.removeLast();
    });
  }

  // --- Delivery Activity Actions ---
  Future<void> _startDeliveryActivity() async {
    try {
      if (!_areActivitiesEnabled) {
        final granted = await FlutterActivityKit.requestPermissions();
        setState(() => _areActivitiesEnabled = granted);
      }

      _deliveryStep = 0;
      final stepData = _deliverySteps[_deliveryStep];

      final session = await FlutterActivityKit.startActivity(
        attributes: const MapActivityAttributes(
          {
            'orderId': 'ORD-54912',
            'restaurant': 'Bella Pizza',
            'customer': 'Daniel',
          },
          customActivityType: 'DeliveryAttributes',
        ),
        content: ActivityContent(
          state: MapActivityContentState(stepData),
          timer: stepData['timer'] as ActivityTimer?,
          relevanceScore: 90.0,
          alert: const ActivityAlert(
            title: 'Order Confirmed',
            body: 'Your pizza order #54912 has been placed.',
          ),
        ),
        iosOptions: const IOSOptions(
          activityType: 'DeliveryAttributes',
        ),
        androidOptions: const AndroidOptions(
          channelId: 'delivery_channel',
          channelName: 'Food Deliveries',
          category: 'progress',
          priority: 2,
          actions: [
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
        ),
      );

      setState(() {
        _deliverySession = session;
      });

      _logEvent('Started Delivery Activity: ${session.id}');

      // Listen to session specific updates
      session.pushTokenStream.listen((token) {
        _logEvent('Session Token Received: ${token.substring(0, 8)}...');
        setState(() {});
      });
    } catch (e) {
      _logEvent('Error starting delivery activity: $e');
    }
  }

  Future<void> _nextDeliveryStep() async {
    if (_deliverySession == null) return;
    if (_deliveryStep >= _deliverySteps.length - 1) return;

    _deliveryStep++;
    final stepData = _deliverySteps[_deliveryStep];

    try {
      await _deliverySession!.update(
        ActivityContent(
          state: MapActivityContentState(stepData),
          timer: stepData['timer'] as ActivityTimer?,
          alert: ActivityAlert(
            title: stepData['title'] as String,
            body: stepData['message'] as String,
          ),
        ),
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
      await _deliverySession!.end(
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

  // --- Sports Match Activity Actions ---
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

      final session = await FlutterActivityKit.startActivity(
        attributes: const MapActivityAttributes(
          {
            'matchId': 'MATCH-REAL-BARCA',
            'homeTeam': 'Real Madrid',
            'awayTeam': 'Barcelona',
            'league': 'Champions League',
          },
          customActivityType: 'SportsAttributes',
        ),
        content: ActivityContent(
          state: MapActivityContentState({
            'title': initialStep['title'] as String,
            'message': initialStep['message'] as String,
            'status': initialStep['status'] as String,
            'progress': _matchMinute / 90.0,
            'homeScore': _homeScore,
            'awayScore': _awayScore,
            'matchMinute': _matchMinute,
          }),
        ),
        androidOptions: const AndroidOptions(
          channelId: 'sports_channel',
          channelName: 'Live Sports',
          category: 'status',
          priority: 2,
          actions: [
            ActivityAction(id: 'match_stats', title: 'Stats'),
            ActivityAction(id: 'mute_match', title: 'Mute'),
          ],
        ),
      );

      setState(() {
        _sportsSession = session;
        _isAutoSimulating = autoSimulate;
      });

      _logEvent('Started Sports Activity: ${session.id}');

      if (autoSimulate) {
        _startSportsAutoSimulation();
      }
    } catch (e) {
      _logEvent('Error starting sports activity: $e');
    }
  }

  void _startSportsAutoSimulation() {
    _sportsAutoTimer?.cancel();
    _isAutoSimulating = true;
    _sportsAutoTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      await _advanceSportsTimeline();
    });
    setState(() {});
  }

  void _toggleSportsAutoSimulation() {
    if (_isAutoSimulating) {
      _sportsAutoTimer?.cancel();
      setState(() => _isAutoSimulating = false);
      _logEvent('Paused Sports auto-simulation');
    } else {
      _startSportsAutoSimulation();
      _logEvent('Resumed Sports auto-simulation');
    }
  }

  Future<void> _advanceSportsTimeline() async {
    if (_sportsSession == null) {
      _sportsAutoTimer?.cancel();
      return;
    }

    if (_autoSimStep < _sportsMatchTimeline.length - 1) {
      _autoSimStep++;
      final step = _sportsMatchTimeline[_autoSimStep];

      setState(() {
        _homeScore = step['home'] as int;
        _awayScore = step['away'] as int;
        _matchMinute = step['minute'] as int;
        _matchEventText = step['message'] as String;
      });

      final alert = step['alert'] as ActivityAlert?;

      try {
        await _sportsSession!.update(
          ActivityContent(
            state: MapActivityContentState({
              'title': step['title'] as String,
              'message': step['message'] as String,
              'status': step['status'] as String,
              'progress': (_matchMinute / 90.0).clamp(0.0, 1.0),
              'homeScore': _homeScore,
              'awayScore': _awayScore,
              'matchMinute': _matchMinute,
            }),
            alert: alert,
          ),
        );
        _logEvent('Auto-Update: ${step['status']} • Score: $_homeScore - $_awayScore');
      } catch (e) {
        _logEvent('Error during auto-update: $e');
      }

      if (_autoSimStep >= _sportsMatchTimeline.length - 1) {
        _sportsAutoTimer?.cancel();
        setState(() => _isAutoSimulating = false);
        _logEvent('🏁 Match simulation reached Full Time');
      }
    } else {
      _sportsAutoTimer?.cancel();
      setState(() => _isAutoSimulating = false);
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
      await _sportsSession!.update(
        ActivityContent(
          state: MapActivityContentState({
            'title': 'Real Madrid vs Barcelona',
            'message': 'GOAL! Score: $_homeScore - $_awayScore',
            'status': 'Live $_matchMinute\'',
            'progress': (_matchMinute / 90.0).clamp(0.0, 1.0),
            'homeScore': _homeScore,
            'awayScore': _awayScore,
            'matchMinute': _matchMinute,
          }),
          alert: ActivityAlert(
            title: '⚽ GOAL!',
            body: homeScored
                ? 'Real Madrid scored! ($_homeScore - $_awayScore)'
                : 'Barcelona scored! ($_homeScore - $_awayScore)',
          ),
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
      await _sportsSession!.end(
        finalContent: ActivityContent(
          state: MapActivityContentState({
            'title': 'Match Ended',
            'message': 'Full Time: Real Madrid $_homeScore - $_awayScore Barcelona',
            'status': 'FT',
            'progress': 1.0,
          }),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Flutter ActivityKit'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_pizza_rounded), text: 'Food Delivery'),
            Tab(icon: Icon(Icons.sports_soccer_rounded), text: 'Live Sports'),
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
                _buildDeliveryTab(theme),
                _buildSportsTab(theme),
                _buildLogsAndTokensTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStatusBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            _isSupported ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 16,
            color: _isSupported ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            _isSupported
                ? 'Supported & Ready'
                : 'Simulator / Platform Unsupported',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (!_areActivitiesEnabled)
            InkWell(
              onTap: () async {
                final granted = await FlutterActivityKit.requestPermissions();
                setState(() => _areActivitiesEnabled = granted);
                _logEvent('Permission request result: $granted');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_open_rounded, size: 12, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text(
                      'Enable Permission',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'Activities: Enabled',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab(ThemeData theme) {
    final currentData = _deliverySteps[_deliveryStep];
    final progress = currentData['progress'] as double;
    final isRunning = _deliverySession != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dynamic Island Live Preview Section
          Text(
            'Dynamic Island & Lock Screen Preview',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Dynamic Island Expanded Preview
          Center(
            child: DynamicIslandPreview(
              style: DynamicIslandStyle.expanded,
              leading: Row(
                children: [
                  const Icon(Icons.local_pizza_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Bella Pizza',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                currentData['eta'] as String,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              center: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentData['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentData['message'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              bottom: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Island Compact Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DynamicIslandPreview(
                style: DynamicIslandStyle.compact,
                leading: Row(
                  children: [
                    const Icon(Icons.local_pizza_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      currentData['status'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
                trailing: Text(
                  currentData['eta'] as String,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const DynamicIslandPreview(
                style: DynamicIslandStyle.minimal,
                leading: Icon(Icons.local_pizza_rounded, color: Colors.amber, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Android Ongoing Notification Preview
          Text(
            'Android Ongoing Notification Preview',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          OngoingNotificationPreview(
            appName: 'Foodie Deliveries',
            subText: 'Order #54912',
            title: currentData['title'] as String,
            body: currentData['message'] as String,
            progress: progress,
            icon: const Icon(Icons.delivery_dining_rounded, size: 16, color: Colors.amber),
            actions: [
              TextButton(
                onPressed: () => _handleActionTap('call_driver'),
                child: const Text('Call Driver'),
              ),
              TextButton(
                onPressed: () => _handleActionTap('cancel_order'),
                child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Controls Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Live Controls (Native ActivityKit / Android Notification)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRunning
                        ? 'Active Session ID: ${_deliverySession!.id}'
                        : 'No activity running currently.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRunning ? Colors.green : Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isRunning)
                    FilledButton.icon(
                      onPressed: _startDeliveryActivity,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Live Activity'),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _deliveryStep < _deliverySteps.length - 1
                                ? _nextDeliveryStep
                                : null,
                            icon: const Icon(Icons.fast_forward_rounded),
                            label: const Text('Next Stage'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: _endDeliveryActivity,
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('End Activity'),
                          ),
                        ),
                      ],
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
          // Scoreboard Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'UEFA Champions League',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white10,
                            radius: 26,
                            child: Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Real Madrid',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '$_homeScore - $_awayScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Column(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white10,
                            radius: 26,
                            child: Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Barcelona',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Live $_matchMinute\'',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lock Screen Banner Simulator
          DynamicIslandPreview(
            style: DynamicIslandStyle.lockScreenBanner,
            title: 'Real Madrid vs Barcelona',
            subtitle: 'UEFA Champions League • Live $_matchMinute\'',
            leading: const Icon(Icons.sports_soccer_rounded, color: Colors.greenAccent),
            trailing: Text(
              '$_homeScore - $_awayScore',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            bottom: Row(
              children: [
                Expanded(
                  child: Text(
                    _matchEventText,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ),
              ],
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isRunning)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isAutoSimulating
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isAutoSimulating
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAutoSimulating ? Icons.timer_outlined : Icons.pause_circle_outline,
                                size: 12,
                                color: _isAutoSimulating ? Colors.green : Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAutoSimulating ? 'Auto (4s ticks)' : 'Paused',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isAutoSimulating ? Colors.green : Colors.amber,
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
                      label: const Text('Start Auto-Simulated Match (4s Ticks)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _startSportsActivity(autoSimulate: false),
                      icon: const Icon(Icons.touch_app_rounded),
                      label: const Text('Start Manual Match'),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _toggleSportsAutoSimulation,
                            icon: Icon(_isAutoSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            label: Text(_isAutoSimulating ? 'Pause Auto' : 'Resume Auto'),
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
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: _pushToStartToken != null
                            ? () {
                                Clipboard.setData(ClipboardData(text: _pushToStartToken!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied token to clipboard')),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _pushToStartToken ?? 'No push-to-start token available.',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Event Log',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _eventLogs.clear()),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: _eventLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No events received yet.\nStart an activity to see live events.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _eventLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            _eventLogs[index],
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                            ),
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
