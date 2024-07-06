import 'package:flutter/material.dart';

class SongItem extends StatelessWidget {
  final String title;
  final String artistName;
  final String imageUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  SongItem({
    required this.title,
    required this.artistName,
    required this.imageUrl,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        artistName,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
        onPressed: onPlayPause,
      ),
    );
  }
}
