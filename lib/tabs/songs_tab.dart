import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../spotify_auth.dart';
import '../spotify_service.dart';
import '../components/song_item.dart';
import '../playerpage.dart';
import 'dart:async';

class SongsTab extends StatefulWidget {
  @override
  _SongsTabState createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> filteredSongs = [];
  List<bool> isSongPlaying = [];
  int currentSongIndex = -1;
  String? accessToken;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchSongs();
    _setupTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      filteredSongs = songs
          .where((song) => song['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _onPlayPause(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPage(
          trackId: filteredSongs[index]['id'],
          trackName: filteredSongs[index]['name'],
          artistName: filteredSongs[index]['artists'][0]['name'],
          coverUrl: filteredSongs[index]['album']['images'][0]['url'],
          accessToken: accessToken!,
        ),
      ),
    );
  }

  Future<void> _fetchSongs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString('spotify_access_token');

      if (accessToken == null) {
        accessToken = await _authenticateWithSpotify();
        if (accessToken == null) {
          // Display an error message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get access token')),
          );
          return;
        }
      }

      setState(() {
        // Show a loading indicator
        songs = [];
      });

      try {
        List<dynamic> fetchedSongs = await SpotifyService(accessToken!).fetchSongsFromPlaylists();
        setState(() {
          songs = List<Map<String, dynamic>>.from(fetchedSongs);
          filteredSongs = songs;
          isSongPlaying = List.generate(songs.length, (index) => false);
        });
      } catch (e) {
        // Display an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load songs: $e')),
        );
      }
    } catch (e) {
      // Display an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load songs: $e')),
      );
    }
  }

  Future<String?> _authenticateWithSpotify() async {
    final spotifyAuthSong = SpotifyAuth(
      clientId: '3292deb19af240a885d7fd118ca150c2',
      clientSecret: '270d5d708804496f9f4d777a57021c28',
      redirectUri: 'momofy3://callback',
      scopes: ['user-read-email', 'playlist-read-private'],
    );

    String? newAccessToken = await spotifyAuthSong.getAccessToken();
    if (newAccessToken != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_access_token', newAccessToken);
    }

    return newAccessToken;
  }

  void _setupTimer() {
    // Refresh the access token every 30 minutes
    Timer.periodic(Duration(minutes: 30), (timer) async {
      String? newAccessToken = await _authenticateWithSpotify();
      if (newAccessToken != null) {
        setState(() {
          accessToken = newAccessToken;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(controller: _searchController),
        const SizedBox(height: 20),
        const Text(
          'Songs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        if (songs.isEmpty)
          const CircularProgressIndicator()
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                return SongItem(
                  title: filteredSongs[index]['name'],
                  artistName: filteredSongs[index]['artists'][0]['name'],
                  imageUrl: filteredSongs[index]['album']['images'][0]['url'],
                  isPlaying: isSongPlaying[index],
                  onPlayPause: () => _onPlayPause(index),
                );
              },
            ),
          ),
      ],
    );
  }
}
