import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert'; //To decode JSON
import 'package:http/http.dart' as http; // To make HTTP requests
import 'package:clidy/config/api.dart'; // import config api
import 'package:clidy/screens/account.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String userId;
  final List<Video> videos; // List of videos to allow swiping between them
  final int initialIndex; // Initial index of the video being played

  VideoPlayerScreen({
    required this.userId,
    required this.videos,
    required this.initialIndex,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  String? profileImageUrl;
  String? username;
  String? videoHashtags;
  String? videoDescription;
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeVideoPlayer(widget.videos[_currentIndex].videoUrl);
    _fetchUserProfile();
    _fetchVideoData(widget.videos[_currentIndex].videoId); // Call to get the video data
  }

  void _initializeVideoPlayer(String videoUrl) {
    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller.play();
        _controller.setLooping(true);
      });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isLoading = true;
    });

    _controller.dispose();
    _initializeVideoPlayer(widget.videos[_currentIndex].videoUrl);
    _fetchVideoData(widget.videos[_currentIndex].videoId); // Update data when changing videos
  }

  Future<void> _fetchVideoData(String videoId) async {
    try {
      final videoData = await API.getVideoData(videoId);
      final comments = await API.getComments(videoId);

      setState(() {
        // Logic is maintained in case you need to restore favorites and comments later
      });
    } catch (e) {
      print('Error getting video data: $e');
    }
  }

  Future<void> _fetchUserProfile() async {
    final url = API.baseUrl;
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'action': 'getUserData',
        'user_id': widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['user'] != null) {
        setState(() {
          profileImageUrl = API.getProfileImageUrl(data['user']['profile_image']);
          username = data['user']['username'];
          videoDescription = data['user']['video_description'];
          videoHashtags = data['user'].containsKey('video_hashtags') ? data['user']['video_hashtags'] : '';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Single Share Icon
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.white, size: 30),
                          onPressed: () {
                            // Implement share action
                          },
                        ),
                        Text('58', style: TextStyle(color: Colors.white)), // Placeholder
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 30,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child: profileImageUrl == null ? CircularProgressIndicator() : null,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          videoDescription ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          videoHashtags ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    radius: 30,
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
