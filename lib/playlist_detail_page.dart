import 'package:flutter/material.dart';
import 'spotify_service.dart';
import 'playerpage.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String accessToken;
  final String playlistId;
  final String playlistName;
  final void Function(Map<String, dynamic> song)
      onSongLongPress; // Add this line

  PlaylistDetailPage({
    required this.accessToken,
    required this.playlistId,
    required this.playlistName,
    required this.onSongLongPress, // Add this line
  });

  @override
  _PlaylistDetailPageState createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late final SpotifyService _spotifyService;
  List<dynamic>? _tracks;
  String? _playlistCoverUrl;

  @override
  void initState() {
    super.initState();
    _spotifyService = SpotifyService(widget.accessToken);
    _fetchPlaylistTracks();
    _fetchPlaylistCover();
  }

  Future<void> _fetchPlaylistTracks() async {
    final tracks = await _spotifyService.fetchPlaylistTracks(widget.playlistId);

    setState(() {
      _tracks = tracks;
    });
  }

  Future<void> _fetchPlaylistCover() async {
    final coverUrl =
        await _spotifyService.fetchPlaylistCover(widget.playlistId);

    setState(() {
      _playlistCoverUrl = coverUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: const Color(0xFFE46E86),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE46E86), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            if (_playlistCoverUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(_playlistCoverUrl!),
                ),
              ),
            _tracks == null
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _tracks!.length,
                      itemBuilder: (context, index) {
                        final track = _tracks![index]['track'];
                        final coverUrl = track['album']['images'][0]['url'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              coverUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            track['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            track['artists'][0]['name'],
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerPage(
                                  trackId: track['id'],
                                  trackName: track['name'],
                                  artistName: track['artists'][0]['name'],
                                  coverUrl: coverUrl,
                                  accessToken: widget.accessToken,
                                ),
                              ),
                            );
                          },
                          onLongPress: () =>
                              widget.onSongLongPress(track), // Add this line
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
