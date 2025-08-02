import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // Import just_audio to play songs
import 'package:clidy/config/api.dart';

class RecordTimer extends StatefulWidget {
  final int maxSeconds; // Maximum recording time
  final VoidCallback onFinish; // Callback function that will be executed upon completion
  final String? selectedSong; // Optional parameter for the selected song

  RecordTimer({
    required this.maxSeconds,
    required this.onFinish,
    this.selectedSong, // Accept the selected song
  });

  @override
  _RecordTimerState createState() => _RecordTimerState();
}

class _RecordTimerState extends State<RecordTimer> {
  int _remainingSeconds = 0;
  Timer? _timer;
  AudioPlayer? _audioPlayer; // Audio player for the song

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.maxSeconds; // Start with maximum seconds
    _audioPlayer = AudioPlayer();
    _startTimer();

    // Play the song if it is selected
    if (widget.selectedSong != null) {
      _playSelectedSong();
    }
  }

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopAudio(); //Stop the song when the time is up
          _timer?.cancel(); //Stop the timer when it reaches 0
          widget.onFinish(); // Call the onFinish callback when the time expires
        }
      });
    });
  }

  // Play the selected song
  Future<void> _playSelectedSong() async {
    final songUrl = '${API.baseUrl.replaceAll('api/api.php', '')}uploads/songs/${widget.selectedSong}';
    try {
      await _audioPlayer!.setUrl(songUrl);
      _audioPlayer!.play(); // Play the song
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  // Stop the selected song
  Future<void> _stopAudio() async {
    await _audioPlayer?.stop();
    _audioPlayer?.dispose();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is destroyed
    _stopAudio(); // Make sure to stop the song
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.7),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recording',
              style: TextStyle(color: Colors.red, fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              '$_remainingSeconds seconds left',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            if (widget.selectedSong != null) // Show the song if it is selected
              Text(
                'Song: ${widget.selectedSong}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
