import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:clidy/screens/account.dart';
import 'package:clidy/screens/upload_video.dart';
import 'package:clidy/config/api.dart';
import 'package:clidy/screens/profiles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clidy/components/home_actions.dart';
import 'package:clidy/screens/explore.dart';
import 'notifications.dart';
import 'package:clidy/screens/upload_web.dart';
import 'package:flutter/foundation.dart';


class VideoFeedUI extends StatefulWidget {
  @override
  _VideoFeedUIState createState() => _VideoFeedUIState();
}

class _VideoFeedUIState extends State<VideoFeedUI> with WidgetsBindingObserver {
  late PageController _pageController;
  List<Map<String, dynamic>> _videos = [];
  int _currentIndex = 0;
  int? _hoveredIndex;
  VideoPlayerController? _controller;
  Set<String> _followedUsers = {};
  Set<String> _favoriteVideos = {};
  // Define `isWeb` here as an instance variable
  bool isWeb = kIsWeb;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadFollowedUsers();
    _loadFavoriteVideos();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) {
      _controller?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _controller?.play();
    } else if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  void _loadFavoriteVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteList = prefs.getStringList('favoriteVideos');

    if (favoriteList != null) {
      setState(() {
        _favoriteVideos = favoriteList.toSet();
      });
    }

    _loadVideos();
  }

  void _saveFavoriteVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favoriteVideos', _favoriteVideos.toList());
  }

  void _loadVideos() async {
    try {
      final List<Map<String, dynamic>> videos = List<Map<String, dynamic>>.from(
        await API.getAllVideos(),
      );

      if (videos.isNotEmpty) {
        setState(() {
          _videos = videos.map((video) {
            return {
              'id': _safeParseInt(video['id']),
              'username': video['username'] ?? 'Unknown User',
              'profile_image': video['profile_image'] ?? '',
              'description': video['description'] ?? 'No description',
              'video_path': video['video_path'],
              'thumbnail': video['thumbnail'],
              'hashtag': video['hashtag'] ?? '',
              'is_favorite': _favoriteVideos.contains(video['id'].toString()),
              'favorites_count': _safeParseInt(video['favorites_count']),
              'comment_count': _safeParseInt(video['comment_count']),
              'user_id': video['user_id'],
            };
          }).toList();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeVideoPlayer(0);
        });
      } else {
        print('No videos found.');
      }
    } catch (e) {
      print('Error loading videos: $e');
    }
  }

  Widget _buildProfileImage(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      return CircleAvatar(
        backgroundImage: AssetImage('assets/default_profile.png'),
        radius: 25,
      );
    }

    return CircleAvatar(
      backgroundImage: NetworkImage(profileImageUrl),
      radius: 25,
      onBackgroundImageError: (_, __) {
        setState(() {});
      },
      child: Icon(Icons.person, color: Colors.white),
    );
  }

  int _safeParseInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 0;
    }
    try {
      return int.parse(value.toString());
    } catch (e) {
      print('Error converting "$value" to integer: $e');
      return 0;
    }
  }

  Future<void> _initializeVideoPlayer(int index) async {
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
    }

    String? videoUrl = _videos[index]['video_path'];
    if (videoUrl == null || videoUrl.isEmpty) {
      print('The video does not have a valid URL');
      return;
    }

    _controller = VideoPlayerController.network(videoUrl);

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        await _controller!.setLooping(true);
        await _controller!.setVolume(1.0);
        await _controller!.play();
      }
    } catch (error) {
      print('Error initializing video: $error');
    }
  }

  void _onPageChanged(int index) {
    if (_controller != null) {
      _controller!.pause();
    }

    setState(() {
      _currentIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideoPlayer(index);
    });
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }


  void _loadFollowedUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? followedList = prefs.getStringList('followedUsers');
    if (followedList != null) {
      setState(() {
        _followedUsers = followedList.toSet();
      });
    }
  }

  void _saveFollowedUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('followedUsers', _followedUsers.toList());
  }

  void _toggleFavorite(int videoId, int index) async {
    bool isFavorite = _favoriteVideos.contains(videoId.toString());

    setState(() {
      if (isFavorite) {
        _favoriteVideos.remove(videoId.toString());
        _videos[index]['is_favorite'] = false;
        _videos[index]['favorites_count'] = (_videos[index]['favorites_count'] ?? 1) - 1;
      } else {
        _favoriteVideos.add(videoId.toString());
        _videos[index]['is_favorite'] = true;
        _videos[index]['favorites_count'] = (_videos[index]['favorites_count'] ?? 0) + 1;
      }
    });

    try {
      if (isFavorite) {
        await API.removeFavorite(videoId.toString());
      } else {
        await API.addFavorite(videoId.toString());
      }
      _saveFavoriteVideos();
    } catch (e) {
      print('Error updating favorites: $e');
    }
  }

  Future<String?> _getFollowerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            if (isWeb) _buildSidebar(context), // Sidebar for Web
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWeb ? 800 : double.infinity,
                  ),
                  child: _videos.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: _onPageChanged,
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      String username = _videos[index]['username'] ?? 'Unknown User';
                      String? profileImageName = _videos[index]['profile_image'];
                      String description = _videos[index]['description'] ?? 'No description';

                      String profileImageUrl = (profileImageName != null && profileImageName.isNotEmpty)
                          ? API.getProfileImageUrl(profileImageName)
                          : 'assets/default_profile.png';

                      return Stack(
                        children: [
                        GestureDetector(
                        behavior: HitTestBehavior.opaque, // Ensures that clicks are detected in the entire area
                        onTap: _togglePlayPause, // We call _togglePlayPause when clicking on the video
                        child: _controller != null && _controller!.value.isInitialized
                            ? SizedBox.expand(
                          child: FittedBox(
                            fit: isWeb ? BoxFit.contain : BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.size?.width ?? 0,
                              height: _controller!.value.size?.height ?? 0,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        )
                            : Center(child: CircularProgressIndicator()),
                        ),
                          Positioned(
                            top: 50,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Following',
                                  style: TextStyle(color: Colors.white70, fontSize: 18),
                                ),
                                SizedBox(width: 20),
                                Text(
                                  'For You',
                                  style: TextStyle(
                                    color: Colors.pink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 150,
                            child: HomeActions(
                              isFavorite: _favoriteVideos.contains(_videos[index]['id'].toString()),
                              favoriteCount: _videos[index]['favorites_count'] ?? 0,
                              commentCount: _videos[index]['comment_count'] ?? 0,
                              onFavoritePressed: () => _toggleFavorite(_videos[index]['id'], index),
                              profileImageUrl: API.getProfileImageUrl(_videos[index]['profile_image'] ?? ''),
                              userId: _videos[index]['user_id']?.toString() ?? '',
                              username: _videos[index]['username'] ?? 'A stranger',
                              videoId: _videos[index]['id'].toString(),
                              secureShareUrl: _videos[index]['video_path'] ?? '',
                              videoTitle: _videos[index]['description'] ?? '',
                              videoDescription: _videos[index]['hashtag'] ?? '',
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 10,
                            right: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@$username',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  key: Key('username_$index'),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  description,
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '#${_videos[index]['hashtag'] ?? ''}',
                                  style: TextStyle(color: Colors.deepPurple, fontSize: 14),
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ],
                      );

                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWeb ? null : _buildBottomNavigationBar(context), // Bottom bar only on mobile
    );
  }

// Construction of the sidebar for the web version
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white10, Colors.black12],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // We add the logo image only for the web version
          Image.asset(
            'assets/logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 30), // Space between logo and menu items

          _buildSidebarItem(
            icon: Icons.home,
            label: 'Home',
            isActive: true,
            onTap: () {
              // Action to navigate to Home
            },
            index: 0,
          ),
          _divider(),
          _buildSidebarItem(
            icon: Icons.explore,
            label: 'Explore',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExploreScreen()),
              );
            },
            index: 1,
          ),
          _divider(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isWeb ? UploadWeb() : UploadVideo(), // Redirect based on device
                ),
              );
            },
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.5),
                    spreadRadius: 8,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 40),
            ),
          ),

          _divider(),
          _buildSidebarItem(
            icon: Icons.notifications,
            label: 'Notification',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
            index: 2,
          ),
          _divider(),
          _buildSidebarItem(
            icon: Icons.person,
            label: 'Profile',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
            index: 3,
          ),
        ],
      ),
    );
  }


  // Helper method for each sidebar element, with improved styling and hover effect
  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required int index,
  }) {
    bool isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: isHovered ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isActive || isHovered
                ? Colors.pinkAccent.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isHovered
                ? [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
                : [],
            border: Border.all(
              color: isActive || isHovered ? Colors.pinkAccent : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive || isHovered ? Colors.pinkAccent : Colors.white70,
                size: 28,
              ),
              SizedBox(width: 20),
              Text(
                label,
                style: TextStyle(
                  color: isActive || isHovered ? Colors.pinkAccent : Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }


// Auxiliary method for the separator between items
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color: Colors.white30,
        thickness: 0.8,
        endIndent: 10,
        indent: 10,
      ),
    );
  }


// Bottom navigation bar for mobile screens only
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        children: [
          IconWithLabel(
            icon: Icons.home,
            label: 'Home',
            color: Colors.pinkAccent,
          ),
          IconWithLabel(
            icon: Icons.explore,
            label: 'Explore',
            color: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExploreScreen()),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isWeb ? UploadWeb() : UploadVideo(), // Redirects based on platform
                ),
              );
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),


          IconWithLabel(
            icon: Icons.notifications,
            label: 'Notification',
            color: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          IconWithLabel(
            icon: Icons.person,
            label: 'Profile',
            color: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
          ),
        ],
      ),
    );
  }


}

class IconWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const IconWithLabel({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
