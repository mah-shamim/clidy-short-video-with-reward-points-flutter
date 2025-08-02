import 'package:flutter/material.dart';
import 'package:clidy/config/api.dart';
import 'redeem_points.dart';

class ActivitySettingsScreen extends StatefulWidget {
  @override
  _ActivitySettingsScreenState createState() => _ActivitySettingsScreenState();
}

class _ActivitySettingsScreenState extends State<ActivitySettingsScreen> {
  Map<String, dynamic>? activitySettings;
  Map<String, dynamic>? pointsAndAmount;
  int userPoints = 0;
  bool isLoadingActivities = true;
  bool isLoadingPoints = true;

  @override
  void initState() {
    super.initState();
    fetchActivitySettings();
    fetchPointsAndAmount();
    fetchUserPoints();
  }

  Future<void> fetchActivitySettings() async {
    try {
      final settings = await API.getActivitySettings();
      if (mounted) {
        setState(() {
          activitySettings = settings;
          isLoadingActivities = false;
        });
      }
    } catch (e) {
      print('Error loading activities: $e');
      if (mounted) setState(() => isLoadingActivities = false);
    }
  }

  Future<void> fetchPointsAndAmount() async {
    try {
      final data = await API.getPointsAndAmount();
      if (mounted) {
        setState(() {
          pointsAndAmount = data;
          isLoadingPoints = false;
        });
      }
    } catch (e) {
      print('Error loading points and amount: $e');
      if (mounted) setState(() => isLoadingPoints = false);
    }
  }

  Future<void> fetchUserPoints() async {
    try {
      String userId = await API.getUserId();
      print('User ID obtained: $userId');

      int points = await API.getUserPoints();
      print('Points obtained: $points');

      if (mounted) {
        setState(() {
          userPoints = points;
        });
      }
    } catch (e) {
      print('Error getting user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Activity Settings'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (isLoadingPoints)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else
          _buildPointsSection(),

        const SizedBox(height: 20),

        if (isLoadingActivities)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (_buildActivityList().isNotEmpty)
          Column(children: _buildActivityList())
        else
          _buildNoActivitiesMessage(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isLoadingPoints)
                CircularProgressIndicator(color: Colors.white)
              else
                _buildWebPointsSection(),

              SizedBox(height: 32),

              if (isLoadingActivities)
                CircularProgressIndicator(color: Colors.white)
              else if (_buildActivityList().isNotEmpty)
                _buildWebActivitiesList()
              else
                _buildNoActivitiesMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsSection() {
    // This is the original mobile version
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'You Have',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$userPoints',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent[400],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reward Points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RedeemPointsScreen()),
                );
              },
              child: const Text(
                'Redeem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pointsAndAmount?['points'] ?? 0} points',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.cyanAccent,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              Text(
                '${pointsAndAmount?['amount'] ?? 0} USD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.greenAccent[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This is the current conversion value between points and currency.',
            style: TextStyle(fontSize: 14, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWebPointsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You Have',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$userPoints',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent[400],
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Reward\nPoints',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  width: 300,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RedeemPointsScreen()),
                      );
                    },
                    child: Text(
                      'Redeem Points',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${pointsAndAmount?['points'] ?? 0} points',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Icon(Icons.arrow_forward, color: Colors.grey, size: 28),
                          ),
                          Text(
                            '${pointsAndAmount?['amount'] ?? 0} USD',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.greenAccent[400],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'This is the current conversion value between points and currency.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebActivitiesList() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Activities',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 32),
          ..._buildActivityList().map((activity) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: activity,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoActivitiesMessage() {
    return const Center(
      child: Text(
        'There are no activities available.',
        style: TextStyle(fontSize: 18, color: Colors.white54),
      ),
    );
  }

  List<Widget> _buildActivityList() {
    List<Widget> activities = [];

    if (activitySettings != null) {
      if (int.parse(activitySettings!['registration_enabled'].toString()) == 1) {
        activities.add(_buildActivityRow(
          'Registration Points',
          activitySettings!['registration_points'].toString(),
        ));
      }
      if (int.parse(activitySettings!['refer_enabled'].toString()) == 1) {
        activities.add(_buildActivityRow(
          'Refer Points',
          activitySettings!['refer_points'].toString(),
        ));
      }
      if (int.parse(activitySettings!['video_enabled'].toString()) == 1) {
        activities.add(_buildActivityRow(
          'Video Points',
          activitySettings!['video_points'].toString(),
        ));
      }
    }
    return activities;
  }

  Widget _buildActivityRow(String name, String points) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Expanded(
        child: Text(
        name,
        style: TextStyle(
          fontSize: isWeb ? 20 : 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    SizedBox(width: 16),
    Text(
    'Points: $points',
    style: TextStyle(fontSize: isWeb ? 20 : 18, color: Colors.white, fontWeight: FontWeight.w500,),
    ),
        ],
      ),
    );
  }
}
