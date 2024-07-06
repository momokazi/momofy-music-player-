import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'song_page.dart';
import 'drawer.dart';
import 'setting.dart';
import 'playlist_detail_page.dart';
import 'spotify_service.dart';
import 'spotify_auth.dart';
import 'recentlyplayed.dart';
import 'playerpage.dart';
import 'package:momofy/tabs/playlist_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  String? _accessToken;
  List<dynamic>? _playlists;
  List<dynamic>? _recommendedPlaylists;
  bool _isLoading = false;
  List<Map<String, dynamic>> _localPlaylists = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
    RecentlyPlayed.loadRecentlyPlayed(); // Load recently played tracks
    _loadLocalPlaylistsFromFirestore();
  }

  Future<void> _deleteAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    setState(() {
      _accessToken = null;
    });
    print('Access token manually deleted');
    _authenticateWithSpotify(); // Refresh the token
  }

  Future<void> _loadAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      setState(() {
        _accessToken = token;
      });
      await _fetchPlaylists();
      _startAccessTokenTimer(); // Start the timer to delete the token after 30 minutes
    } else {
      _authenticateWithSpotify();
    }
  }

  void _handlePlaylistLongPress(Map<String, dynamic> playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Playlist'),
          content: Text(
              'Do you want to add ${playlist['name']} to your local list?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // Add your logic to add the playlist to the local list here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _authenticateWithSpotify() async {
    setState(() {
      _isLoading = true;
    });

    final spotifyAuth = SpotifyAuth(
      clientId: '3292deb19af240a885d7fd118ca150c2',
      clientSecret: '270d5d708804496f9f4d777a57021c28',
      redirectUri: 'momofy3://callback',
      scopes: ['user-read-email', 'playlist-read-private'],
    );

    final accessToken = await spotifyAuth.authenticate();

    if (accessToken != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('access_token', accessToken);

      setState(() {
        _accessToken = accessToken;
      });

      await _fetchPlaylists();
      _startAccessTokenTimer(); // Start the timer to delete the token after 30 minutes
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPlaylists() async {
    if (_accessToken != null) {
      final spotifyService = SpotifyService(_accessToken!);
      final userPlaylists = await spotifyService.fetchPlaylists();
      final recommendedPlaylists =
          await spotifyService.fetchRecommendedPlaylists();

      setState(() {
        _playlists = userPlaylists;
        _recommendedPlaylists = recommendedPlaylists;
      });
    }
  }

  void _startAccessTokenTimer() {
    Timer(Duration(minutes: 30), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('access_token');
      setState(() {
        _accessToken = null;
      });
      print('Access token deleted after 30 minutes');
      _authenticateWithSpotify(); // Refresh the token
    });
  }

  void _showSongAddedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Song added successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddToLocalPlaylistDialog(Map<String, dynamic> song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _localPlaylists.map((playlist) {
              return ListTile(
                title: Text(playlist['name']),
                onTap: () {
                  _addSongToLocalPlaylist(song, playlist['id']);
                  Navigator.of(context).pop();
                  _showSongAddedSnackBar();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _loadLocalPlaylistsFromFirestore() async {
    QuerySnapshot querySnapshot =
        await _firestore.collection('local_playlists').get();
    List<Map<String, dynamic>> localPlaylists = querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'songs': List<Map<String, dynamic>>.from(doc['songs'].map((song) => {
              'id': song['id'],
              'name': song['name'],
              'previewUrl': song['previ'
                  'ew_url'],
              'album': {
                'images': song['album']['images'],
              },
              'artists': song['artists'],
            })),
      };
    }).toList();
    setState(() {
      _localPlaylists = localPlaylists;
    });
  }

  void _handleSongLongPress(Map<String, dynamic> song) {
    _showAddToLocalPlaylistDialog(song);
  }

  Future<void> _addSongToLocalPlaylist(
      Map<String, dynamic> song, String playlistId) async {
    setState(() {
      final playlistIndex = _localPlaylists
          .indexWhere((playlist) => playlist['id'] == playlistId);
      if (playlistIndex != -1) {
        final playlist = _localPlaylists[playlistIndex];
        final songExists = playlist['songs'].any((s) => s['id'] == song['id']);
        if (!songExists) {
          playlist['songs'].add(song);
        }
      }
    });

    await _saveLocalPlaylistsToFirestore();
  }

  Future<void> _saveLocalPlaylistsToFirestore() async {
    WriteBatch batch = _firestore.batch();
    for (var playlist in _localPlaylists) {
      DocumentReference ref =
          _firestore.collection('local_playlists').doc(playlist['id']);
      batch.set(ref, {
        'name': playlist['name'],
        'songs': playlist['songs']
            .map((song) => {
                  'id': song['id'],
                  'name': song['name'],
                  'preview_url': song['previewUrl'],
                  'album': {
                    'images': song['album']['images'],
                  },
                  'artists': song['artists'],
                })
            .toList(),
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE46E86),
        title: Row(
          children: [
            const Center(
              child: Text(
                'Momofy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 141),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteAccessToken,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFE46E86),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _currentIndex == 0
          ? _buildHomePageContent()
          : _currentIndex == 1
              ? SongsPage()
              : _currentIndex == 2
                  ? SettingsPage()
                  : Container(),
    );
  }

  Widget _buildHomePageContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Highly Recommended',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 200,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recommendedPlaylists == null
                    ? const Center(
                        child: Text('No recommended playlists available.'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedPlaylists!.length,
                        itemBuilder: (BuildContext context, int index) {
                          final playlist = _recommendedPlaylists![index];
                          final coverImageUrl = playlist['images'].isNotEmpty
                              ? playlist['images'][0]['url']
                              : null;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaylistDetailPage(
                                    accessToken: _accessToken!,
                                    playlistId: playlist['id'],
                                    playlistName: playlist['name'],
                                    onSongLongPress: _handleSongLongPress,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _handlePlaylistLongPress(playlist);
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F2F2F),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      image: coverImageUrl != null
                                          ? DecorationImage(
                                              image:
                                                  NetworkImage(coverImageUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      playlist['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: Colors.white,
              thickness: 1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your Playlists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 200,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _playlists == null
                    ? const Center(child: Text('No playlists available.'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _playlists!.length,
                        itemBuilder: (BuildContext context, int index) {
                          final playlist = _playlists![index];
                          final coverImageUrl = playlist['images'].isNotEmpty
                              ? playlist['images'][0]['url']
                              : null;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaylistDetailPage(
                                    accessToken: _accessToken!,
                                    playlistId: playlist['id'],
                                    playlistName: playlist['name'],
                                    onSongLongPress: _handleSongLongPress,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _handlePlaylistLongPress(playlist);
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F2F2F),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      image: coverImageUrl != null
                                          ? DecorationImage(
                                              image:
                                                  NetworkImage(coverImageUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      playlist['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: Colors.white,
              thickness: 1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Recently Played',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: RecentlyPlayed.recentlyPlayed.length,
            itemBuilder: (BuildContext context, int index) {
              final track = RecentlyPlayed.recentlyPlayed[index];
              final coverUrl = track['coverUrl'] ?? '';
              final trackName = track['trackName'] ?? 'Unknown Track';
              final artistName = track['artistName'] ?? 'Unknown Artist';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerPage(
                        trackId: track['trackId']!,
                        trackName: track['trackName']!,
                        artistName: track['artistName']!,
                        coverUrl: track['coverUrl']!,
                        accessToken: _accessToken!,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    children: [
                      Image.network(coverUrl, width: 40, height: 40),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trackName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artistName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
