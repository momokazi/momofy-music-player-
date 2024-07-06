import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecentlyPlayed {
  static List<Map<String, String>> recentlyPlayed = [];

  static Future<void> addTrack(String trackId, String trackName, String artistName, String coverUrl) async {
    // Check if the track is already in the list, if so, remove it and re-add to the top
    recentlyPlayed.removeWhere((track) => track['trackId'] == trackId);
    recentlyPlayed.insert(0, {
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'coverUrl': coverUrl,
    });

    // Limit the list to the last 10 played tracks
    if (recentlyPlayed.length > 10) {
      recentlyPlayed = recentlyPlayed.sublist(0, 10);
    }

    // Store the updated list in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('recently_played', jsonEncode(recentlyPlayed));
  }

  static Future<void> loadRecentlyPlayed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('recently_played');
    if (jsonString != null) {
      List<dynamic> jsonResponse = jsonDecode(jsonString);
      recentlyPlayed = jsonResponse.map((track) => Map<String, String>.from(track)).toList();
    }
  }
}
