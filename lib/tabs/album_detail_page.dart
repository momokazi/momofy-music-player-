import 'package:flutter/material.dart';
import '../spotify_service.dart';
import 'package:momofy/playerpage.dart';
import 'package:momofy/playlist_detail_page.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;
  final String accessToken;
  final String playlistId;

  AlbumDetailPage({
    required this.albumId,
    required this.albumName,
    required this.accessToken,
    required this.playlistId,
  });

  @override
  _AlbumDetailPageState createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late final SpotifyService _spotifyService;
  Map<String, dynamic>? _albumDetails;
  bool _isLoading = true;
  String? _playlistCoverUrl;

  @override
  void initState() {
    super.initState();
    _spotifyService = SpotifyService(widget.accessToken);
    _fetchAlbumDetails();
    _fetchPlaylistCover();
  }

  Future<void> _fetchAlbumDetails() async {
    try {
      final albumDetails =
      await _spotifyService.fetchAlbumDetails(widget.albumId);
      setState(() {
        _albumDetails = albumDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching album details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPlaylistCover() async {
    final coverUrl = await _spotifyService.fetchPlaylistCover(widget.playlistId);

    setState(() {
      _playlistCoverUrl = coverUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE46E86),
        title: Text(widget.albumName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _albumDetails == null
          ? const Center(child: Text('No album details available.'))
          : Column(
        children: [
          if (_playlistCoverUrl != null &&
              _isValidUrl(_playlistCoverUrl!))
            Image.network(_playlistCoverUrl!),
          const SizedBox(height: 20),
          Text(
            _albumDetails!['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _albumDetails!['tracks']['items'].length,
              itemBuilder: (context, index) {
                final track = _albumDetails!['tracks']['items'][index];
                final albumImage = _albumDetails!['images'].isNotEmpty
                    ? _albumDetails!['images'][0]['url']
                    : null;
                return ListTile(
                  leading: albumImage != null
                      ? Image.network(albumImage, width: 50, height: 50)
                      : const Icon(Icons.music_note, size: 50),
                  title: Text(track['name']),
                  subtitle: Text(track['artists'][0]['name']),
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerPage(
                          trackId: track['id'],
                          trackName: track['name'],
                          artistName: track['artists'][0]['name'],
                          coverUrl: albumImage ?? '', // Use album image URL
                          accessToken: widget.accessToken,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}
