import 'package:flutter/material.dart';
import 'package:clidy/config/api.dart';
import 'package:video_player/video_player.dart';
import 'package:clidy/screens/videos_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilesScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String profileImageUrl;

  ProfilesScreen({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
  }) {
    if (userId.isEmpty) {
      throw ArgumentError('The userId cannot be null or empty.');
    }
    print('ProfileScreen initialized with userId: $userId');
  }

  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late Future<List<Map<String, dynamic>>> _userVideos;
  int videoCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _userVideos = Future.value([]);
    _loadUserDataAndVideos();
    _loadFollowingState();
  }

  void _loadUserDataAndVideos() async {
    try {
      Map<String, dynamic> userData = await API.getUserData(widget.userId);
      print('User data received: $userData');

      if (userData.containsKey('followers') && userData.containsKey('following')) {
        setState(() {
          _followersCount = int.tryParse(userData['followers'].toString()) ?? 0;
          _followingCount = int.tryParse(userData['following'].toString()) ?? 0;
        });
      }

      List<dynamic> rawVideos = await API.getUserVideosWithHashtags(widget.userId);
      List<Map<String, dynamic>> videos = rawVideos
          .map((video) => video as Map<String, dynamic>)
          .toList();

      setState(() {
        videoCount = videos.length;
        _userVideos = Future.value(videos);
      });

    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _loadFollowingState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? followedList = prefs.getStringList('followedUsers');

    if (followedList != null && followedList.contains(widget.userId)) {
      setState(() {
        _isFollowing = true;
      });
    }
  }

  void _updateFollowingState(bool isFollowing) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? followedList = prefs.getStringList('followedUsers') ?? [];

    if (isFollowing) {
      followedList.add(widget.userId);
    } else {
      followedList.remove(widget.userId);
    }

    prefs.setStringList('followedUsers', followedList);
  }

  Future<String?> _getFollowerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Widget _buildInfoColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: () async {
        String? followerId = await _getFollowerId();
        if (followerId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error following user. Try again.')),
          );
          return;
        }
        setState(() {
          _isFollowing = !_isFollowing;
        });

        try {
          if (_isFollowing) {
            await API.addFollower(widget.userId, followerId);
            setState(() {
              _followersCount += 1;
            });
          } else {
            await API.removeFollower(widget.userId, followerId);
            setState(() {
              _followersCount -= 1;
            });
          }
        } catch (e) {
          print('Error updating followers: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating followers. Try again.')),
          );
        }
        _updateFollowingState(_isFollowing);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? Colors.redAccent : Colors.pinkAccent,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(
        _isFollowing ? 'Unfollow' : 'Follow',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 900 : double.infinity),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 30 : 16),
                  decoration: isWeb
                      ? BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  )
                      : null,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: isWeb ? 70 : 50,
                        backgroundImage: widget.profileImageUrl.isNotEmpty
                            ? NetworkImage(API.getProfileImageUrl(widget.profileImageUrl))
                            : AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                      SizedBox(height: 20),

                      Text(
                        widget.username,
                        style: TextStyle(
                          fontSize: isWeb ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Statistics information and Follow button only on the Web
                      if (isWeb)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoColumn('$videoCount', 'Posts'),
                            SizedBox(width: 40),
                            _buildInfoColumn('$_followersCount', 'Followers'),
                            SizedBox(width: 40),
                            _buildInfoColumn('$_followingCount', 'Following'),
                            SizedBox(width: 40),
                            _buildFollowButton(),
                          ],
                        )
                      else
                      // Statistics information on mobile (without Follow button in the same row)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoColumn('$videoCount', 'Posts'),
                            SizedBox(width: 20),
                            _buildInfoColumn('$_followersCount', 'Followers'),
                            SizedBox(width: 20),
                            _buildInfoColumn('$_followingCount', 'Following'),
                          ],
                        ),
                      // Botón Follow en móvil (debajo del Row)
                      if (!isWeb) SizedBox(height: 20),
                      if (!isWeb) _buildFollowButton(),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _userVideos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.white));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading videos: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'This user does not have videos.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    } else {
                      List<Map<String, dynamic>> videos = snapshot.data!;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWeb ? 3 : 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          String? videoPath = videos[index]['video_path'];
                          String? thumbnailPath = videos[index]['thumbnail'];

                          if (videoPath == null || thumbnailPath == null) {
                            return Center(
                              child: Text('Video not available', style: TextStyle(color: Colors.white)),
                            );
                          }

                          String videoThumbnailUrl = API.getThumbnailUrl(thumbnailPath);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideosProfileScreen(
                                    videos: videos,
                                    initialIndex: index,
                                    username: widget.username,
                                    profileImageUrl: widget.profileImageUrl,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    videoThumbnailUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text('Error loading thumbnail', style: TextStyle(color: Colors.white)),
                                      );
                                    },
                                  ),
                                ),
                                Center(
                                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
