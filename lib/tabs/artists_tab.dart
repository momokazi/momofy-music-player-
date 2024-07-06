import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/search_bar.dart' as custom;
import '../spotify_auth.dart';
import '../spotify_service.dart';
import 'artist_detail_page.dart';

class ArtistsTab extends StatefulWidget {
  @override
  _ArtistsTabState createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> artists = [];
  List<Map<String, dynamic>> filteredArtists = [];
  bool _isLoading = true;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _authenticateAndFetchArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      filteredArtists = artists
          .where((artist) => artist['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _authenticateAndFetchArtists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('spotify_access_token');
    int? savedTime = prefs.getInt('token_timestamp');

    if (accessToken == null || savedTime == null || DateTime.now().millisecondsSinceEpoch - savedTime > 1800000) {
      final spotifyAuthArtist = SpotifyAuth(
        clientId: '3292deb19af240a885d7fd118ca150c2',
        clientSecret: '270d5d708804496f9f4d777a57021c28',
        redirectUri: 'momofy3://callback',
        scopes: ['user-read-email', 'playlist-read-private'],
      );

      accessToken = await spotifyAuthArtist.authenticate();
      if (accessToken != null) {
        await prefs.setString('spotify_access_token', accessToken);
        await prefs.setInt('token_timestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        // Display an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get access token')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    _accessToken = accessToken;
    await _fetchArtists();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchArtists() async {
    if (_accessToken != null) {
      final spotifyService = SpotifyService(_accessToken!);
      final fetchedArtists = await spotifyService.fetchArtistsFromPlaylists();

      setState(() {
        artists = fetchedArtists;
        filteredArtists = artists;
      });
    }
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
          'Artists',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredArtists.length,
            itemBuilder: (context, index) {
              final artist = filteredArtists[index];
              final coverImageUrl = artist['images'].isNotEmpty
                  ? artist['images'][0]['url']
                  : null;
              return ListTile(
                leading: coverImageUrl != null
                    ? Image.network(coverImageUrl, width: 50, height: 50)
                    : Icon(Icons.person, size: 50),
                title: Text(
                  artist['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ArtistDetailPage(
                        accessToken: _accessToken!,
                        artistId: artist['id'],
                        artistName: artist['name'],
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
