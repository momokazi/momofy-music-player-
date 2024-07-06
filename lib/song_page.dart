import 'package:flutter/material.dart';
import 'tabs/songs_tab.dart';
import 'tabs/albums_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/playlist_tab.dart';

class SongsPage extends StatefulWidget {
  final int initialIndex;

  SongsPage({this.initialIndex = 0});

  @override
  _SongsPageState createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<IconData> _tabIcons = [
    Icons.music_note,
    Icons.album,
    Icons.person,
    Icons.playlist_play,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.index = widget.initialIndex;
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_tabIcons[_tabController.index]),
            const SizedBox(width: 8),
            Text(
              _getTabName(_tabController.index),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE46E86),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Align(
            alignment: Alignment.center,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'Songs'),
                Tab(text: 'Albums'),
                Tab(text: 'Artists'),
                Tab(text: 'Playlists'),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            SongsTab(),
            AlbumsTab(playlistId: 'Qasim'),
            ArtistsTab(),
            PlaylistsTab(),
          ],
        ),
      ),
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Songs';
      case 1:
        return 'Albums';
      case 2:
        return 'Artists';
      case 3:
        return 'Playlists';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
