import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

import '../spotify_auth.dart';
import '../spotify_service.dart';
import '../playlist_detail_page.dart';
import '../playerpage.dart'; // Ensure this import path is correct based on your project structure

class PlaylistsTab extends StatefulWidget {
  @override
  _PlaylistsTabState createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  String? _accessToken;
  List<dynamic>? _playlists;
  bool _isLoading = false;
  List<Map<String, dynamic>> _localPlaylists = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
    _loadLocalPlaylistsFromFirestore();
  }

  Future<void> _loadAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      setState(() {
        _accessToken = accessToken;
      });
      await _fetchPlaylists();
    } else {
      _authenticateWithSpotify();
    }
  }

  Future<void> _loadLocalPlaylistsFromFirestore() async {
    QuerySnapshot querySnapshot = await _firestore.collection('local_playlists').get();
    List<Map<String, dynamic>> localPlaylists = querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'songs': List<Map<String, dynamic>>.from(doc['songs'].map((song) => {
          'id': song['id'],
          'name': song['name'],
          'previewUrl': song['previewUrl'], // Correct field name here
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

  Future<void> _saveLocalPlaylistsToFirestore() async {
    WriteBatch batch = _firestore.batch();
    for (var playlist in _localPlaylists) {
      DocumentReference ref = _firestore.collection('local_playlists').doc(playlist['id']);
      batch.set(ref, {
        'name': playlist['name'],
        'songs': playlist['songs'].map((song) => {
          'id': song['id'],
          'name': song['name'],
          'preview_url': song['previewUrl'],
          'album': {
            'images': song['album']['images'],
          },
          'artists': song['artists'],
        }).toList(),
      });
    }
    await batch.commit();
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
      await prefs.setString('access_token', accessToken);

      setState(() {
        _accessToken = accessToken;
      });

      await _fetchPlaylists();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPlaylists() async {
    if (_accessToken != null) {
      final spotifyService = SpotifyService(_accessToken!);
      final playlists = await spotifyService.fetchPlaylists();

      setState(() {
        _playlists = playlists;
      });
    }
  }

  Future<void> _createLocalPlaylist(String name) async {
    final newPlaylist = {
      'id': _firestore.collection('local_playlists').doc().id,
      'name': name,
      'songs': [],
    };
    setState(() {
      _localPlaylists.add(newPlaylist);
    });

    await _saveLocalPlaylistsToFirestore();
  }

  Future<void> _addSongToLocalPlaylist(Map<String, dynamic> song, String playlistId) async {
    setState(() {
      final playlistIndex = _localPlaylists.indexWhere((playlist) => playlist['id'] == playlistId);
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

  void _showCreatePlaylistDialog() {
    final _playlistNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: TextField(
            controller: _playlistNameController,
            decoration: const InputDecoration(
              hintText: 'Enter playlist name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                _createLocalPlaylist(_playlistNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteLocalPlaylist(Map<String, dynamic> playlist) async {
    setState(() {
      _localPlaylists.removeWhere((pl) => pl['id'] == playlist['id']);
    });
    await _firestore.collection('local_playlists').doc(playlist['id']).delete();
  }

  void _showLocalPlaylistDetailPage(Map<String, dynamic> playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocalPlaylistDetailPage(
          playlist: playlist,
          onDelete: () {
            _deleteLocalPlaylist(playlist);
            Navigator.of(context).pop();
          },
          onDeleteSong: (song) {
            _removeSongFromLocalPlaylist(playlist, song);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _removeSongFromLocalPlaylist(Map<String, dynamic> playlist, Map<String, dynamic> song) async {
    setState(() {
      final playlistIndex = _localPlaylists.indexWhere((pl) => pl['id'] == playlist['id']);
      if (playlistIndex != -1) {
        _localPlaylists[playlistIndex]['songs'].removeWhere((s) => s['id'] == song['id']);
      }
    });

    await _saveLocalPlaylistsToFirestore();
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

  void _showSongAddedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Song added successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accessToken == null
          ? ElevatedButton(
        onPressed: _authenticateWithSpotify,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE46E86),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Login with Spotify',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : ListView.builder(
        itemCount: (_playlists?.length ?? 0) + _localPlaylists.length,
        itemBuilder: (context, index) {
          if (index < _localPlaylists.length) {
            final localPlaylist = _localPlaylists[index];
            return ListTile(
              leading: const Icon(Icons.playlist_play, size: 50),
              title: Text(localPlaylist['name']),
              onTap: () {
                _showLocalPlaylistDetailPage(localPlaylist);
              },
            );
          } else {
            final spotifyIndex = index - _localPlaylists.length;
            final playlist = _playlists![spotifyIndex];
            final coverImageUrl =
            playlist['images'].isNotEmpty ? playlist['images'][0]['url'] : null;
            return ListTile(
              leading: coverImageUrl != null
                  ? Image.network(coverImageUrl, width: 50, height: 50)
                  : const Icon(Icons.music_note, size: 50),
              title: Text(playlist['name']),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailPage(
                      accessToken: _accessToken!,
                      playlistId: playlist['id'],
                      playlistName: playlist['name'],
                      onSongLongPress: _showAddToLocalPlaylistDialog,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: _accessToken != null
          ? FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFFE46E86),
      )
          : null,
    );
  }
}

class LocalPlaylistDetailPage extends StatefulWidget {
  final Map<String, dynamic> playlist;
  final void Function() onDelete;
  final void Function(Map<String, dynamic>) onDeleteSong;

  LocalPlaylistDetailPage({
    required this.playlist,
    required this.onDelete,
    required this.onDeleteSong,
  });

  @override
  _LocalPlaylistDetailPageState createState() =>
      _LocalPlaylistDetailPageState();
}

class _LocalPlaylistDetailPageState extends State<LocalPlaylistDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrackId;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }


  void _playPauseTrack(Map<String, dynamic> song) async {
    String? previewUrl = song['previewUrl'];
    if (previewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this track')),
      );
      return;
    }

    if (_isPlaying && _currentTrackId == song['id']) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(UrlSource(previewUrl));
      setState(() {
        _isPlaying = true;
        _currentTrackId = song['id'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.playlist['songs'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE46E86),
        title: Text(widget.playlist['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final coverUrl = song['album']['images'][0]['url'];

          return ListTile(
            leading: coverUrl != null
                ? Image.network(
              coverUrl,
              width: 50,
              height: 50,
            )
                : const Icon(Icons.music_note, size: 50),
            title: Text(song['name']),
            subtitle: Text(song['artists'].map((a) => a['name']).join(', ')),
            trailing: IconButton(
              icon: Icon(
                _currentTrackId == song['id'] && _isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                _playPauseTrack(song);
              },
            ),
            onTap: () {
              _playPauseTrack(song);
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Remove Song'),
                    content: const Text('Do you want to remove this song from the playlist?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          widget.onDeleteSong(song);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Song removed successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Yes'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('No'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
