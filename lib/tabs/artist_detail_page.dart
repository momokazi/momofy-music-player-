import 'package:flutter/material.dart';
import '../spotify_service.dart';
import 'package:momofy/playerpage.dart';

class ArtistDetailPage extends StatefulWidget {
  final String accessToken;
  final String artistId;
  final String artistName;

  ArtistDetailPage({
    required this.accessToken,
    required this.artistId,
    required this.artistName,
  });

  @override
  _ArtistDetailPageState createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late final SpotifyService _spotifyService;
  Map<String, dynamic>? _artistDetails;
  List<Map<String, dynamic>> _topTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _spotifyService = SpotifyService(widget.accessToken);
    _fetchArtistDetails();
    _fetchArtistTopTracks();
  }

  Future<void> _fetchArtistDetails() async {
    try {
      final details = await _spotifyService.fetchArtistDetails(widget.artistId);
      setState(() {
        _artistDetails = details;
      });
    } catch (error) {
      print('Failed to fetch artist details: $error');
    }
  }

  Future<void> _fetchArtistTopTracks() async {
    try {
      final topTracks = await _spotifyService.fetchArtistTopTracks(widget.artistId);
      setState(() {
        _topTracks = topTracks;
        _isLoading = false;
      });
    } catch (error) {
      print('Failed to fetch artist top tracks: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_artistDetails != null && _artistDetails!['images'] != null && _artistDetails!['images'].isNotEmpty)
                Image.network(_artistDetails!['images'][0]['url']),
              const SizedBox(height: 20),
              Text(
                _artistDetails != null ? _artistDetails!['name'] : '',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_artistDetails != null)
                Text(
                  'Followers: ${_artistDetails!['followers']['total']}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 10),
              if (_artistDetails != null)
                Text(
                  'Genres: ${(_artistDetails!['genres'] as List).join(', ')}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Top Tracks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_topTracks.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _topTracks.length,
                  itemBuilder: (context, index) {
                    final track = _topTracks[index];
                    final albumImage = track['album']['images'].isNotEmpty ? track['album']['images'][0]['url'] : null;
                    return ListTile(
                      leading: albumImage != null ? Image.network(albumImage, width: 50, height: 50) : Icon(Icons.music_note, size: 50),
                      title: Text(track['name']),
                      subtitle: Text(track['album']['name']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerPage(
                              trackId: track['id'],
                              trackName: track['name'],
                              artistName: widget.artistName,
                              coverUrl: albumImage ?? '',
                              accessToken: widget.accessToken,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
