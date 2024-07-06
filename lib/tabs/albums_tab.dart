import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/search_bar.dart' as custom;
import '../spotify_auth.dart';
import '../spotify_service.dart';
import 'album_detail_page.dart';

class AlbumsTab extends StatefulWidget {
  final String playlistId;

  AlbumsTab({super.key, required this.playlistId});

  @override
  _AlbumsTabState createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> albums = [];
  List<Map<String, dynamic>> filteredAlbums = [];
  bool _isLoading = true;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _authenticateAndFetchAlbums();
    _setupTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      filteredAlbums = albums
          .where((album) => album['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _authenticateAndFetchAlbums() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('spotify_access_token');

    if (accessToken == null) {
      final spotifyAuthAlbum = SpotifyAuth(
        clientId: '3292deb19af240a885d7fd118ca150c2',
        clientSecret: '270d5d708804496f9f4d777a57021c28',
        redirectUri: 'momofy3://callback',
        scopes: ['user-read-email', 'playlist-read-private'],
      );

      accessToken = await spotifyAuthAlbum.authenticate();
      if (accessToken != null) {
        await prefs.setString('spotify_access_token', accessToken);
      } else {
        // Display an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get access token')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    _accessToken = accessToken;
    await _fetchAlbumsFromPlaylists();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAlbumsFromPlaylists() async {
    if (_accessToken != null) {
      final spotifyService = SpotifyService(_accessToken!);
      final fetchedAlbums = await spotifyService.fetchAlbumsFromPlaylists();

      setState(() {
        albums = fetchedAlbums;
        filteredAlbums = albums;
      });
    }
  }

  void _setupTimer() {
    // Refresh the access token every 50 minutes
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      SpotifyAuth spotifyAuthAlbum = SpotifyAuth(
        clientId: '3292deb19af240a885d7fd118ca150c2',
        clientSecret: '270d5d708804496f9f4d777a57021c28',
        redirectUri: 'momofy3://callback',
        scopes: ['user-read-email', 'playlist-read-private'],
      );

      _accessToken = await spotifyAuthAlbum.authenticate();
      if (_accessToken != null) {
        await prefs.setString('spotify_access_token', _accessToken!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        custom.SearchBar(controller: _searchController),
        const SizedBox(height: 20),
        const Text(
          'Albums',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredAlbums.length,
            itemBuilder: (context, index) {
              final album = filteredAlbums[index];
              final coverImageUrl = album['images'].isNotEmpty
                  ? album['images'][0]['url']
                  : null;
              return ListTile(
                leading: coverImageUrl != null
                    ? Image.network(coverImageUrl, width: 50, height: 50)
                    : const Icon(Icons.album, size: 50),
                title: Text(
                  album['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailPage(
                        playlistId: widget.playlistId,
                        accessToken: _accessToken!,
                        albumId: album['id'],
                        albumName: album['name'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
