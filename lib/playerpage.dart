import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'spotify_service.dart';
import 'recentlyplayed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PlayerPage extends StatefulWidget {
  final String trackId;
  final String trackName;
  final String artistName;
  final String coverUrl;
  final String accessToken;

  PlayerPage({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.coverUrl,
    required this.accessToken,
  });

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with SingleTickerProviderStateMixin {
  late final SpotifyService _spotifyService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _previewUrl;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _animationController;
  bool _hasPlayedForTwoSeconds = false;
  bool _isRepeat = false;
  bool _isShuffle = false;

  @override
  void initState() {
    super.initState();
    _spotifyService = SpotifyService(widget.accessToken);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _setAudioPlayerListeners();
    _playTrack();
  }

  void _setAudioPlayerListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          if (!_hasPlayedForTwoSeconds && position.inSeconds >= 2) {
            _hasPlayedForTwoSeconds = true;
            _addToRecentlyPlayed();
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRepeat) {
        _playTrack();
      } else {
        setState(() {
          _isPlaying = false;
          _animationController.reverse();
        });
      }
    });
  }

  void _addToRecentlyPlayed() {
    RecentlyPlayed.addTrack(
      widget.trackId,
      widget.trackName,
      widget.artistName,
      widget.coverUrl,
    ).then((_) {
      // Handle success or error if needed
    }).catchError((error) {
      // Handle error if needed
      print('Error adding to recently played: $error');
    });
  }

  Future<void> _playTrack() async {
    final previewUrl = await _spotifyService.playTrack(widget.trackId);

    if (mounted) {
      setState(() {
        _previewUrl = previewUrl;
      });
    }

    if (previewUrl != null) {
      await _audioPlayer.play(UrlSource(previewUrl));
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
        _animationController.forward();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview URL not available')),
      );
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        _animationController.reverse();
      }
    } else {
      if (_previewUrl != null) {
        await _audioPlayer.play(UrlSource(_previewUrl!));
        if (mounted) {
          _animationController.forward();
        }
      }
    }
    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _seekForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition < _duration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  void _seekBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    }
  }

  void _showAddToPlaylistDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddToPlaylistDialog(
          song: {
            'id': widget.trackId,
            'name': widget.trackName,
            'artists': [
              {'name': widget.artistName}
            ],
            'album': {
              'images': [
                {'url': widget.coverUrl}
              ]
            },
            'previewUrl': _previewUrl, // Include previewUrl here
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFE46E86);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(widget.trackName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showAddToPlaylistDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Hero(
                    tag: widget.coverUrl,
                    child: Image.network(
                      widget.coverUrl,
                      fit: BoxFit.cover,
                      height: 300,
                      width: 300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.trackName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.artistName,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_previewUrl == null)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          icon: Icon(Icons.replay_10, color: themeColor),
                          onPressed: _seekBackward,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 64,
                          icon: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _animationController,
                            color: themeColor,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 48,
                          icon: Icon(Icons.forward_10, color: themeColor),
                          onPressed: _seekForward,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      activeColor: themeColor,
                      inactiveColor: Colors.grey[600],
                      value: _position.inSeconds.toDouble(),
                      max: _duration.inSeconds.toDouble(),
                      onChanged: (value) async {
                        final newPosition = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(newPosition);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _position.toString().split('.').first.padLeft(8, "0"),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          _duration.toString().split('.').first.padLeft(8, "0"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                              _isRepeat ? Icons.repeat_one : Icons.repeat,
                              color: themeColor),
                          onPressed: () {
                            setState(() {
                              _isRepeat = !_isRepeat;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                              _isShuffle ? Icons.shuffle_on : Icons.shuffle,
                              color: themeColor),
                          onPressed: () {
                            setState(() {
                              _isShuffle = !_isShuffle;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: themeColor),
                          onPressed: () {
                            // Play previous track
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: themeColor),
                          onPressed: () {
                            // Play next track
                          },
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddToPlaylistDialog extends StatefulWidget {
  final Map<String, dynamic> song;

  AddToPlaylistDialog({required this.song});

  @override
  _AddToPlaylistDialogState createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  late Future<List<String>> _playlistsFuture;
  String? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _fetchPlaylists();
  }

  Future<List<String>> _fetchPlaylists() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('local_playlists').get();
    final List<String> playlistNames = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
    return playlistNames;
  }

  Future<void> _addSongToPlaylist(String playlistName) async {
    final CollectionReference playlists = FirebaseFirestore.instance.collection('local_playlists');
    final QuerySnapshot querySnapshot = await playlists.where('name', isEqualTo: playlistName).get();

    if (querySnapshot.docs.isNotEmpty) {
      final DocumentReference playlistDoc = querySnapshot.docs.first.reference;
      await playlistDoc.update({
        'songs': FieldValue.arrayUnion([widget.song]),
      });

      Fluttertoast.showToast(
        msg: 'Song added to $playlistName',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to add song to $playlistName',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to Playlist'),
      content: FutureBuilder<List<String>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No playlists found');
          } else {
            final playlists = snapshot.data!;
            return DropdownButton<String>(
              isExpanded: true,
              value: _selectedPlaylist,
              onChanged: (newValue) {
                setState(() {
                  _selectedPlaylist = newValue;
                });
              },
              items: playlists.map<DropdownMenuItem<String>>((String playlist) {
                return DropdownMenuItem<String>(
                  value: playlist,
                  child: Text(playlist),
                );
              }).toList(),
            );
          }
        },
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Add'),
          onPressed: _selectedPlaylist == null
              ? null
              : () {
            _addSongToPlaylist(_selectedPlaylist!);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
