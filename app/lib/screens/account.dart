import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clidy/config/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clidy/layout/edit_profile.dart';
import 'package:clidy/layout/settings.dart';
import 'package:clidy/layout/my_posts.dart';
class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _username = '';
  String? _profileImageUrl;
  String _userId = '';
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;
  List<Video> _videos = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserVideos();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';

    try {
      Map<String, dynamic> userData = await API.getUserData(_userId);
      setState(() {
        _username = userData['username'] ?? '';
        _profileImageUrl = userData['profile_image'];
        _followersCount = int.tryParse(userData['followers'].toString()) ?? 0;
        _followingCount = int.tryParse(userData['following'].toString()) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';

    try {
      final response = await http.post(
        Uri.parse(API.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "getUserVideos",
          "user_id": _userId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['videos'];
        setState(() {
          _videos = data.map((json) => Video.fromJson(json)).toList();
        });
      } else {
        print('Error fetching videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }

  Future<void> _updateUserData(String newUsername, String newProfileImageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
    await prefs.setString('profile_image_url', newProfileImageUrl);

    setState(() {
      _username = newUsername;
      _profileImageUrl = newProfileImageUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: Colors.white),
            onSelected: (String value) {
              if (value == 'Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              } else if (value == 'Edit Profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfile()),
                ).then((result) {
                  if (result != null && result is Map<String, dynamic>) {
                    String newUsername = result['username'];
                    String newProfileImageUrl = result['profile_image_url'];
                    _updateUserData(newUsername, newProfileImageUrl);
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'Edit Profile', child: Text('Edit Profile')),
              PopupMenuItem(value: 'Settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 600;

          return _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: isWeb ? 60 : 45,
                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? NetworkImage(API.getProfileImageUrl(_profileImageUrl!))
                            : NetworkImage('https://via.placeholder.com/150'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _username.isNotEmpty ? _username : 'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWeb ? 28 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatColumn('$_followersCount', 'Followers'),
                          SizedBox(width: 24),
                          _buildStatColumn('$_followingCount', 'Following'),
                          SizedBox(width: 24),
                          _buildStatColumn('${_videos.length}', 'Posts'),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: isWeb ? 200 : double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfile()),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        String newUsername = result['username'];
                        String newProfileImageUrl = result['profile_image_url'];
                        await _updateUserData(newUsername, newProfileImageUrl);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Edit profile', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 30),
                // Título "Videos"
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Video grid with improved thumbnail styling
                _videos.isEmpty
                    ? Center(
                  child: Text(
                    'No videos available.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _videos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWeb ? 4 : 3,
                    crossAxisSpacing: isWeb ? 12 : 8,
                    mainAxisSpacing: isWeb ? 12 : 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              userId: _userId,
                              videos: _videos,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey[900],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(API.getThumbnailUrl(video.thumbnailUrl)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget for displaying stats (Followers, Following, Posts)
  Column _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class Video {
  final String videoId;
  final String thumbnailUrl;
  final String videoUrl;

  Video({
    required this.videoId,
    required this.thumbnailUrl,
    required this.videoUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      videoId: json['id'],
      thumbnailUrl: API.getThumbnailUrl(json['thumbnail']),
      videoUrl: API.getVideoUrl(json['video_path']),
    );
  }
}
