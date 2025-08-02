import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:shared_preferences/shared_preferences.dart'; // For handling `SharedPreferences`

class API {
  // Define only one base URL to avoid duplications and facilitate future changes
  static const String _baseRootUrl = "https://democlidy.dkawo.com/";

  // Use this base URL for the main API
  static const String baseUrl = "${_baseRootUrl}api/api.php";

  // Method to generate the full URL of the profile image
  static String getProfileImageUrl(String imageName) {
    if (imageName.startsWith('http')) {
      return imageName;
    }
    // Ensure the image name is concatenated properly
    return "${_baseRootUrl}uploads/profile_image/$imageName";
  }

  // Method to generate the full URL of the video
  static String getVideoUrl(String videoPath) {
    if (videoPath.startsWith('http')) {
      return videoPath;
    }
    return "${_baseRootUrl}$videoPath";
  }

  // Method to generate the full URL of the thumbnail
  static String getThumbnailUrl(String thumbnailPath) {
    if (thumbnailPath.startsWith('http')) {
      return thumbnailPath;
    }
    // Check if the path already contains 'uploads/thumbnails' to avoid duplicates
    if (thumbnailPath.contains('uploads/thumbnails')) {
      return "${_baseRootUrl}$thumbnailPath";
    }
    // Otherwise, add 'uploads/thumbnails'
    return "${_baseRootUrl}uploads/thumbnails/$thumbnailPath";
  }

  // Method to get the `userId` from `SharedPreferences`
  static Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('user_id') ?? '';  // If not found, return an empty string
    print('Retrieved user_id: $userId');  // Add this log to verify
    return userId;
  }

// ------------------------------------ COMMENT METHODS ------------------------------------

// Method to add a comment to a video
  static Future<void> addComment(String videoId, String comment) async {
    try {
      // Get the current userId from `SharedPreferences`
      String userId = await getUserId(); // After

      print('Adding comment for video_id: $videoId by user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'addComment',
          'video_id': videoId,
          'user_id': userId, // Including the commenter’s `user_id`
          'comment': comment // The comment being added
        }),
      );

      if (response.statusCode == 201) {
        print('Comment added successfully.');
      } else {
        print('Error adding comment. Status code: ${response.statusCode}');
        throw Exception('Failed to add comment.');
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow; // Re-throw the error for further handling
    }
  }

// Method to get comments for a video
  static Future<List<dynamic>> getComments(String videoId) async {
    try {
      print('Getting comments for video_id: $videoId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'getComments',
          'video_id': videoId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['comments'] != null) {
          return data['comments']; // List of comments
        } else {
          print('No comments available for this video.');
          return []; // Return empty list if there are no comments
        }
      } else {
        print('Error getting comments. Status code: ${response.statusCode}');
        throw Exception('Failed to get comments.');
      }
    } catch (e) {
      print('Error getting comments: $e');
      rethrow;
    }
  }

// Generate full URL for music
  static String getMusicFileUrl(String musicFile) {
    if (musicFile.startsWith('http')) {
      return musicFile;
    }
    return "${_baseRootUrl}uploads/songs/$musicFile";
  }


  // ------------------------------------ OTHER EXISTING METHODS ----------------------------------

// Method to get user videos along with their description and hashtags
  static Future<List<dynamic>> getUserVideosWithHashtags(String userId) async {
    try {
      print('Requesting videos for user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'getUserVideosWithHashtags',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if relevant fields (thumbnail, hashtag, music_file) are present
        print('Received video data: $data');

        if (data != null && data.containsKey('videos') && data['videos'] is List) {
          List<dynamic> videos = data['videos'];

          // Make sure to handle each optional field (thumbnail, hashtag, music_file)
          return videos.map((video) => {
            'id': video['id'],
            'description': video['description'] ?? '',
            'video_path': video['video_path'],  // Using the API's direct URL
            'thumbnail': video['thumbnail'],  // Using the API's direct URL
            'hashtag': video['hashtag'] ?? 'No hashtags',
            'profile_image': video['profile_image'] ?? '',  // Profile image from API
            'music_file': video['music_file'] ?? '',
            'created_date': video['created_date'],
          }).toList();

        } else {
          print('No videos found for this user.');
          throw Exception('No videos found for this user.');
        }
      } else {
        print('Error loading videos. Status code: ${response.statusCode}');
        throw Exception('Failed to load videos.');
      }
    } catch (e) {
      print('Error retrieving videos with hashtags: $e');
      rethrow;
    }
  }

// Method to get user data (profile, followers, and following)
  static Future<Map<String, dynamic>> getUserData(String userId) async {
    if (userId.isEmpty) {
      print('Error: userId is empty or invalid');
      throw Exception('The userId is invalid.');
    }

    try {
      print('Requesting user data for user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'getUserData',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          return {
            "id": data['user']['id'],
            "name": data['user']['name'],
            "username": data['user']['username'],
            "email": data['user']['email'],
            "profile_image": data['user']['profile_image'],
            "followers": data['user']['followers'],
            "following": data['user']['following'],
            "points": data['user']['points'],
          };
        } else {
          print('User not found in API response.');
          throw Exception('User not found.');
        }
      } else {
        print('Error loading user data. Status code: ${response.statusCode}');
        throw Exception('Failed to load user data.');
      }
    } catch (e) {
      print('Error retrieving user data: $e');
      rethrow;
    }
  }




  // Method to get details of a specific video by ID
  static Future<Map<String, dynamic>> getVideoData(String videoId) async {
    try {
      print('Requesting video data for video_id: $videoId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'getVideoData',
          'video_id': videoId,
        }),
      );

      print('Status code: ${response.statusCode}');
      print('JSON Response: ${response.body}'); // Check the complete response here

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Video data: $data'); // Verify if favorites_count, username, and profile_image are present

        if (data['video'] != null) {
          return data['video'];
        } else {
          print('Video not found in API response.');
          throw Exception('Video not found.');
        }
      } else {
        print('Error loading video data. Status code: ${response.statusCode}');
        throw Exception('Failed to load video data.');
      }
    } catch (e) {
      print('Error retrieving video data: $e');
      rethrow;
    }
  }

// Method to get all available videos
  static Future<List<dynamic>> getAllVideos() async {
    try {
      String userId = await getUserId();

      print('Requesting all videos for user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'getAllVideos',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Received video data: $data'); // Log to verify the content.

        if (data['videos'] != null) {
          return data['videos'];
        } else {
          print('No videos available.');
          return [];
        }
      } else {
        print('Error loading videos. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error retrieving all videos: $e');
      return [];
    }
  }


  // Method to add a follower
  static Future<void> addFollower(String userId, String followerId) async {
    try {
      print('Adding follower for user_id: $userId, follower_id: $followerId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'addFollower',
          'user_id': userId,
          'follower_id': followerId,
        }),
      );

      if (response.statusCode == 200) {
        print('Follower added successfully.');
      } else {
        print('Error adding follower. Status code: ${response.statusCode}');
        throw Exception('Failed to add follower.');
      }
    } catch (e) {
      print('Error adding follower: $e');
      rethrow;
    }
  }

// Method to remove a follower
  static Future<void> removeFollower(String userId, String followerId) async {
    try {
      print('Removing follower for user_id: $userId, follower_id: $followerId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'removeFollower',
          'user_id': userId,
          'follower_id': followerId,
        }),
      );

      if (response.statusCode == 200) {
        print('Follower removed successfully.');
      } else {
        print('Error removing follower. Status code: ${response.statusCode}');
        throw Exception('Failed to remove follower.');
      }
    } catch (e) {
      print('Error removing follower: $e');
      rethrow;
    }
  }

// Method to add a favorite to a video
  static Future<void> addFavorite(String videoId) async {
    try {
      // Get the userId from `SharedPreferences`
      String userId = await getUserId(); // Then

      print('Adding favorite for video_id: $videoId by user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'addFavorite',
          'video_id': videoId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Favorite added successfully.');
      } else {
        print('Error adding favorite. Status code: ${response.statusCode}');
        throw Exception('Failed to add favorite.');
      }
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }


// Method to obtain reward system settings
  static Future<Map<String, dynamic>> getRewardSettings() async {
    try {
      print('Fetching reward system settings.');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'action': 'getRewardSettings'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reward_settings'] != null) {
          print('Settings obtained: ${data['reward_settings']}');
          return data['reward_settings']; // Returns reward settings
        } else {
          print('Reward settings not found.');
          throw Exception('Reward settings not found.');
        }
      } else {
        print('Error fetching settings. Code: ${response.statusCode}');
        throw Exception('Failed to fetch reward settings.');
      }
    } catch (e) {
      print('Error fetching reward settings: $e');
      rethrow;
    }
  }


  // Method to obtain points, amount, and currency code
  static Future<Map<String, dynamic>> getPointsAndAmount() async {
    try {
      print('Fetching points, amount, and currency code.');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'action': 'getPointsAndAmount'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['points_and_amount'] != null) {
          print('Data obtained: ${data['points_and_amount']}');
          return {
            'points': data['points_and_amount']['points'],
            'amount': data['points_and_amount']['amount'],
            'currency_code': data['currency_code'], // USD
          };
        } else {
          print('No data found.');
          throw Exception('No points and amount data found.');
        }
      } else {
        print('Error fetching points and amount. Code: ${response.statusCode}');
        throw Exception('Failed to fetch points and amount.');
      }
    } catch (e) {
      print('Error fetching points and amount: $e');
      rethrow;
    }
  }

// Method to obtain the user's current points
  static Future<int> getUserPoints() async {
    try {
      String userId = await getUserId();

      print('Fetching points for user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'getUserPoints',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Points response: ${data['points']}');
        return int.tryParse(data['points'].toString()) ?? 0;
      } else {
        print('Error fetching points. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch user points.');
      }
    } catch (e) {
      print('Error fetching points: $e');
      rethrow;
    }
  }


// Method to obtain activity settings
  static Future<Map<String, dynamic>> getActivitySettings() async {
    try {
      print('Fetching activity settings.');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'action': 'getActivitySettings'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['activity_settings'] != null) {
          print('Activity settings: ${data['activity_settings']}');
          return data['activity_settings']; // Returns the settings
        } else {
          throw Exception('No activity settings found.');
        }
      } else {
        print('Error fetching activities. Code: ${response.statusCode}');
        throw Exception('Failed to fetch activity settings.');
      }
    } catch (e) {
      print('Error fetching activity settings: $e');
      rethrow;
    }
  }

// Add this method in the API class for searching
  static Future<List<dynamic>> searchVideos(String query) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'searchVideos',
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Data received from search: $data'); // Verify data here
        return data['videos'] ?? [];
      } else {
        print('Error in search. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error performing search: $e');
      return [];
    }
  }




// Method to remove a favorite from a video
  static Future<void> removeFavorite(String videoId) async {
    try {
      // Get the userId from `SharedPreferences`
      String userId = await getUserId(); // Then

      print('Removing favorite for video_id: $videoId by user_id: $userId');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'removeFavorite',
          'video_id': videoId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Favorite removed successfully.');
      } else {
        print('Error removing favorite. Status code: ${response.statusCode}');
        throw Exception('Failed to remove favorite.');
      }
    } catch (e) {
      print('Error removing favorite: $e');
      rethrow;
    }
  }
}
