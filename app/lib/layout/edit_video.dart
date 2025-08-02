import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_session/audio_session.dart';
import 'songs.dart'; // Import the Songs file to select songs
import 'package:clidy/config/api.dart';
import 'package:fluttertoast/fluttertoast.dart'; // To display messages
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart'; // Import FFmpeg Kit
import 'video_record.dart'; // Import VideoRecord for navigation

class EditVideo extends StatefulWidget {
  final String videoPath;

  EditVideo({required this.videoPath});

  @override
  _EditVideoState createState() => _EditVideoState();
}

class _EditVideoState extends State<EditVideo> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _selectedAudioUrl; // URL of the selected audio
  String? _selectedAudioName; // Name of the selected audio file
  Duration _audioDuration = Duration.zero; // Total audio duration
  Duration _audioPosition = Duration.zero; // Current audio position
  bool _isAudioReady = false; // Flag to indicate that the audio is ready
  bool _isVideoReady = false; // Flag to indicate that the video is ready

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initializeAudioSession();
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
        _videoController?.setVolume(0.0);  // Disable video audio
        setState(() {
          _isVideoReady = true; // The video is ready to play
        });
      });
  }

  // Save video with audio (combination of video and audio)
  void _saveVideoWithAudio() async {
    if (_selectedAudioUrl != null) {
      // Here we combine the video and audio using FFmpeg
      String outputPath = widget.videoPath.replaceAll('.mp4', '_output.mp4'); // Generate a new output file

      String command = '-i ${widget.videoPath} -i $_selectedAudioUrl -c:v copy -c:a aac -strict experimental $outputPath';

      Fluttertoast.showToast(msg: 'Saving the video with the selected audio...');

      // Ejecutar el comando de FFmpeg
      FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (returnCode?.isValueSuccess() == true) {
          // El video con audio ha sido guardado exitosamente
          Fluttertoast.showToast(msg: 'Video saved successfully');

          // Navigate to the VideoRecordScreen screen with the new video and audio name selected
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoRecordScreen( // Fixed: VideoRecordScreen
                videoPath: outputPath,
                audioUrl: _selectedAudioUrl,
                audioName: _selectedAudioName, // Pass the song name
              ),
            ),
          );
        } else {
          // There was an error saving the video
          Fluttertoast.showToast(msg: 'Error saving video');
        }
      });
    } else {
      Fluttertoast.showToast(msg: 'Please select an audio before saving');
    }
  }

  // Start or pause video and audio playback
  void _togglePlayPause() async {
    if (_isPlaying) {
      // Pause both media
      _videoController?.pause();
      _audioPlayer.pause();
    } else {
      // Make sure both video and audio are ready
      if (_isVideoReady && (_selectedAudioUrl == null || _isAudioReady)) {
        // If there is an audio selected, play it in sync with the video
        if (_selectedAudioUrl != null) {
          await _audioPlayer.seek(_videoController!.value.position);
          _audioPlayer.play(); // Play audio
        }
        _videoController?.play(); // Play video
      }
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Method to select an audio track from Songs.dart
  Future<void> _selectAudio() async {
    final selectedSongFile = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Songs()),
    );

    if (selectedSongFile != null) {
      // Create the full URL of the selected song
      String newAudioUrl = '${API.baseUrl.replaceAll('api/api.php', '')}uploads/songs/$selectedSongFile';

      // Pause audio and video before changing song
      _pause();

      setState(() {
        _selectedAudioUrl = newAudioUrl; // Save the URL of the new song
        _selectedAudioName = selectedSongFile; // Save the song name
      });

      // Replace the current audio with the new selected song
      try {
        await _audioPlayer.setUrl(_selectedAudioUrl!);

        // Get the total duration of the audio
        _audioPlayer.durationStream.listen((duration) {
          setState(() {
            _audioDuration = duration ?? Duration.zero; // Save audio duration
            _isAudioReady = true; // Audio is ready
          });
        });

        // Listen for changes in audio position
        _audioPlayer.positionStream.listen((position) {
          setState(() {
            _audioPosition = position; // Save current audio position
          });
        });

        _play(); // Resume playback with the new song
      } catch (e) {
        print('Error loading new song: $e');
      }
    }
  }

  // Pause synchronized playback
  void _pause() {
    _videoController?.pause();
    _audioPlayer.pause();
  }

  // Play in sync with new song
  void _play() {
    if (_selectedAudioUrl != null && _isAudioReady) {
      // Sync audio with video if audio is selected
      _audioPlayer.seek(_videoController!.value.position);
      _audioPlayer.play();
    }
    _videoController?.play();
  }

  // Display the duration in MM:SS format
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
      appBar: AppBar(
        title: Text('Edit Video'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Video section
          _videoController != null && _videoController!.value.isInitialized
              ? Container(
            height: MediaQuery.of(context).size.height * 0.4, // 40% from the screen
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
                Center(
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 80,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
              ],
            ),
          )
              : Container(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),

          // Slider bar to show the position of the video and audio
          _videoController != null && _videoController!.value.isInitialized
              ? Slider(
            value: _videoController!.value.position.inSeconds.toDouble(),
            max: _videoController!.value.duration.inSeconds.toDouble(),
            onChanged: (value) {
              final position = Duration(seconds: value.toInt());
              _videoController?.seekTo(position);
              _audioPlayer.seek(position); // Sync Audio
            },
            activeColor: Colors.orange,
            inactiveColor: Colors.white,
          )
              : Container(),

          // Slider bar for audio track
          if (_selectedAudioUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Slider(
                    value: _audioPosition.inSeconds.toDouble(),
                    max: _audioDuration.inSeconds.toDouble(),
                    onChanged: (value) {
                      final newPosition = Duration(seconds: value.toInt());
                      _audioPlayer.seek(newPosition); // Change audio position
                      _videoController?.seekTo(newPosition); // Sync with video
                    },
                    activeColor: Colors.green,
                    inactiveColor: Colors.white,
                  ),
                  // Show the current and total duration of the audio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audioPosition), //Show current audio position
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatDuration(_audioDuration), // Show total audio duration
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Button to add audio from Songs.dart
          ElevatedButton.icon(
            onPressed: _selectAudio,
            icon: Icon(Icons.music_note),
            label: Text("Add Audio"),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white,
              backgroundColor: Colors.pink,
            ),
          ),

          // Show if there is an audio track selected
          _selectedAudioUrl != null
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Audio added: $_selectedAudioName", // Show the song name
              style: TextStyle(color: Colors.white),
            ),
          )
              : Container(),

          // Save button
          ElevatedButton.icon(
            onPressed: _saveVideoWithAudio, // Action when pressing the save button
            icon: Icon(Icons.save),
            label: Text("Save video"),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white,
              backgroundColor: Colors.pink,
            ),
          ),
        ],
      ),
    );
  }
}
