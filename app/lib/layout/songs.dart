import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clidy/config/api.dart'; // Make sure you have the api.dart file imported
import 'package:just_audio/just_audio.dart'; // Import the just_audio dependency
// here we are left with changing the language from es to en
// Model Song
class Song {
  final String singer;
  final String title;
  final String category;
  final String duration;
  final String file;

  Song({
    required this.singer,
    required this.title,
    required this.category,
    required this.duration,
    required this.file,
  });

  // Method to create a Song object from a JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      singer: json['singer'] ?? 'Unknown',
      title: json['song_title'] ?? 'Untitled',
      category: json['category'] ?? 'No Category',
      duration: json['song_duration'] ?? '0:00',
      file: json['song_file'] ?? '',
    );
  }
}

class Songs extends StatefulWidget {
  @override
  _SongsState createState() => _SongsState();
}

class _SongsState extends State<Songs> {
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _hasError = false;
  AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance
  String _currentSongFile = ''; // File of the currently playing song
  Duration _currentPosition = Duration.zero; // Current position of the song
  bool _isPlaying = false; // Controls whether a song is playing

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  // Method to get the songs from the API
  Future<void> _fetchSongs() async {
    try {
      final response = await http.post(
        Uri.parse(API.baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'getSongs'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> songsJson = data['songs'] ?? [];

        setState(() {
          _songs = songsJson.map((json) => Song.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load songs');
      }
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // Method to play/pause the audio file
  void _playSong(String fileName) async {
    if (_currentSongFile == fileName && _isPlaying) {
      // If the current song is playing, pause it
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // We stop the current song if there is one playing
      await _audioPlayer.stop();

      String url = '${API.baseUrl.replaceAll('api/api.php', '')}uploads/songs/$fileName'; // URL completa del archivo MP3
      try {
        await _audioPlayer.setUrl(url); // Set the URL of the audio file
        await _audioPlayer.play(); // Play the file
        setState(() {
          _isPlaying = true;
          _currentSongFile = fileName;
          _currentPosition = Duration.zero; // Reset the position of the new song
        });

        // Listen to the current position of the song
        _audioPlayer.positionStream.listen((position) {
          if (_currentSongFile == fileName) {
            setState(() {
              _currentPosition = position;
            });
          }
        });
      } catch (error) {
        print('Error playing file: $error');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Release the player when it is no longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Add Scaffold here
      backgroundColor: Colors.black, // Sets the black background of the Scaffold
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
            SizedBox(height: 10),

            // If there is an error, display a message
            if (_hasError)
              Center(
                child: Text(
                  'Error loading songs',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

            // Show charging indicator if charging
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Colors.purple,
                ),
              )
            else if (_songs.isEmpty)
            // If there are no songs, show message
              Center(
                child: Text(
                  'No songs available.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
            // List of loaded songs
              Expanded(
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isCurrentSong = song.file == _currentSongFile;

                    return ListTile(
                      leading: GestureDetector(
                        // Inside ListTile
                        onTap: () {
                          // Return the URL of the selected song to `edit_video.dart`
                          Navigator.pop(context, song.file);
                        },

                        child: Icon(
                          isCurrentSong && _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: isCurrentSong && _isPlaying
                              ? Colors.green
                              : Colors.purple,
                          size: 40,
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          // Return the URL of the selected song to `video_record.dart`
                          Navigator.pop(context, song.file);
                        },
                        child: Text(
                          song.title,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${song.singer} - ${song.category}\n${song.duration}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          if (isCurrentSong && _isPlaying) // Show position if it is the active song
                            Text(
                              'Playing: ${_currentPosition.toString().split('.').first}',
                              style: TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                      trailing: Icon(Icons.bookmark_border, color: Colors.white),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
