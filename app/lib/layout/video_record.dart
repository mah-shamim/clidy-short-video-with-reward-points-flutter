import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_session/audio_session.dart';
import 'edit_video.dart';
import 'post_video.dart';

class VideoRecordScreen extends StatefulWidget { // I changed the class name here
  final String videoPath;
  final String? audioUrl;
  final String? audioName; // Add audio name

  VideoRecordScreen({required this.videoPath, this.audioUrl, this.audioName});

  @override
  _VideoRecordScreenState createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends State<VideoRecordScreen> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioSession();
    _initializeVideoPlayer();
    if (widget.audioUrl != null) {
      _initializeAudioPlayer(widget.audioUrl!);
    }
  }

// Initialize the audio session
  Future<void> _initializeAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  // Initialize the video player
  void _initializeVideoPlayer() {
    final videoFile = File(widget.videoPath);

    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {}); // Update status when video is ready
      });
  }

  // Initialize the audio player
  void _initializeAudioPlayer(String audioUrl) async {
    try {
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.setLoopMode(LoopMode.all); // Repeat audio if necessary
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  // Play or pause both media
  void _togglePlayPause() async {
    if (_isPlaying) {
      // Pause both media
      _videoController?.pause();
      _audioPlayer.pause();
    } else {
      // Sync audio position with video before playing
      await _audioPlayer.seek(_videoController!.value.position);

      // Play both media
      _videoController?.play();
      _audioPlayer.play();
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Function to navigate to the editing screen
  void _navigateToEditVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVideo(videoPath: widget.videoPath),
      ),
    );
  }

// Function to navigate to the PostVideo screen
  void _navigateToPostVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostVideo(
          videoPath: widget.videoPath,
          audioName: widget.audioName, // Pass the audio name to PostVideo
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show video
          _videoController != null && _videoController!.value.isInitialized
              ? Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
              : Center(child: CircularProgressIndicator()),

          // Play/pause button in the center
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: _togglePlayPause, // Calls the function that plays or pauses
                ),
              ],
            ),
          ),

          // Buttons at the top right
          Positioned(
            top: 40,
            right: 10,
            child: Row(
              children: [
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 30),
                  onPressed: _navigateToEditVideo, // Navigate to the editing screen
                ),
                SizedBox(width: 10), // Space between buttons
                // Botón de check
                IconButton(
                  icon: Icon(Icons.check, color: Colors.white, size: 30),
                  onPressed: _navigateToPostVideo, // Navigate to the PostVideo screen
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
