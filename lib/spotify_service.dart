import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {
  final String accessToken;

  SpotifyService(this.accessToken);

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final url = Uri.https('api.spotify.com', '/v1/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    return json.decode(response.body);
  }

  Future<String?> fetchPlaylistCover(String playlistId) async {
    final url =
    Uri.https('api.spotify.com', '/v1/playlists/$playlistId/images');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> images = json.decode(response.body);
      if (images.isNotEmpty) {
        return images[0]['url'];
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> createPlaylist(String name) async {
    final url = Uri.https('api.spotify.com', '/v1/users/me/playlists');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'public': false, // Set to true if you want the playlist to be public
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create playlist');
    }
  }

  Future<List<dynamic>> fetchPlaylists() async {
    final url = Uri.https('api.spotify.com', '/v1/me/playlists');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    print('fetchPlaylists status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      return json.decode(response.body)['items'];
    } else {
      print('fetchPlaylists error: ${response.body}');
      return [];
    }
  }

  Future<List<dynamic>> fetchRecommendedPlaylists() async {
    final url = Uri.https('api.spotify.com', '/v1/browse/featured-playlists');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['playlists']['items'];
    } else {
      throw Exception('Failed to load recommended playlists');
    }
  }

  Future<List<dynamic>> fetchPlaylistTracks(String playlistId) async {
    final url =
    Uri.https('api.spotify.com', '/v1/playlists/$playlistId/tracks');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    print('fetchPlaylistTracks status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      return json.decode(response.body)['items'];
    } else {
      print('fetchPlaylistTracks error: ${response.body}');
      return [];
    }
  }

  Future<String?> fetchAlbumCover(String albumId) async {
    final url = Uri.https('api.spotify.com', '/v1/albums/$albumId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final album = json.decode(response.body);
      final List<dynamic> images = album['images'];
      if (images.isNotEmpty) {
        return images[0]['url'];
      }
    }
    return null;
  }

  Future<String?> playTrack(String trackId) async {
    final url = Uri.https('api.spotify.com', '/v1/tracks/$trackId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['preview_url'];
    } else {
      throw Exception('Failed to load preview URL');
    }
  }

  Future<List<String>> fetchSongs() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/tracks'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> songs = (data['items'] as List)
          .map((track) => track['track']['name'].toString())
          .toList();
      return songs;
    } else {
      throw Exception('Failed to fetch songs');
    }
  }

  Future<List<dynamic>> fetchSongsFromPlaylists() async {
    List<dynamic> songs = [];
    final playlists = await fetchPlaylists();

    for (var playlist in playlists) {
      final tracks = await fetchPlaylistTracks(playlist['id']);
      for (var item in tracks) {
        final track = item['track'];
        if (!songs.any((s) => s['id'] == track['id'])) {
          songs.add(track);
        }
      }
    }

    return songs;
  }

  Future<List<Map<String, dynamic>>> fetchArtistsFromPlaylists() async {
    List<Map<String, dynamic>> artists = [];
    final playlists = await fetchPlaylists();

    print('Fetched ${playlists.length} playlists.');
    for (var playlist in playlists) {
      final tracks = await fetchPlaylistTracks(playlist['id']);
      print('Fetched ${tracks.length} tracks from playlist ${playlist['id']}.');
      for (var item in tracks) {
        final track = item['track'];
        for (var artist in track['artists']) {
          if (!artists.any((a) => a['id'] == artist['id'])) {
            artists.add({
              'id': artist['id'],
              'name': artist['name'],
              'images': track['album']['images']
            });
          }
        }
      }
    }

    print('Fetched ${artists.length} unique artists.');
    return artists;
  }

  Future<List<Map<String, dynamic>>> fetchAlbums(String artistId) async {
    final url = Uri.https('api.spotify.com', '/v1/artists/$artistId/albums');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    print('fetchAlbums status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Albums fetched: ${data['items']}'); // Debug statement
      return List<Map<String, dynamic>>.from(data['items']);
    } else {
      print('fetchAlbums error: ${response.body}');
      throw Exception('Failed to load albums');
    }
  }

  Future<Map<String, dynamic>> fetchArtistDetails(String artistId) async {
    final url = Uri.https('api.spotify.com', '/v1/artists/$artistId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load artist details');
    }
  }

  Future<Map<String, dynamic>> fetchAlbumDetails(String albumId) async {
    final url = Uri.https('api.spotify.com', '/v1/albums/$albumId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load album details');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAlbumsFromPlaylists() async {
    List<Map<String, dynamic>> albums = [];
    final playlists = await fetchPlaylists();

    print('Fetched ${playlists.length} playlists.');
    for (var playlist in playlists) {
      final tracks = await fetchPlaylistTracks(playlist['id']);
      print('Fetched ${tracks.length} tracks from playlist ${playlist['id']}.');
      for (var item in tracks) {
        final album = item['track']['album'];
        if (!albums.any((a) => a['id'] == album['id'])) {
          albums.add(album);
        }
      }
    }

    print('Fetched ${albums.length} unique albums.');
    return albums;
  }

  Future<String> getLyrics(String trackId) async {
    // Replace this with the actual endpoint and logic to fetch lyrics
    final url = Uri.https('api.lyrics.ovh', '/v1/spotify/$trackId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['lyrics'];
    } else {
      throw Exception('Failed to load lyrics');
    }
  }

  Future<List<Map<String, dynamic>>> fetchArtistTopTracks(String artistId) async {
    final url = Uri.https('api.spotify.com', '/v1/artists/$artistId/top-tracks', {'market': 'US'});
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['tracks']);
    } else {
      throw Exception('Failed to fetch artist top tracks');
    }
  }
}
