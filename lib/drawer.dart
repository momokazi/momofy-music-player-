import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setting.dart';
import 'song_page.dart';
import 'login_page.dart';
import 'spotify_service.dart';
import 'spotify_auth.dart';
import 'update_user_info.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _accessToken;
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _playlists;
  bool _isSpotifyLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSpotifyLoginStatus();
  }

  Future<void> _checkSpotifyLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('spotify_access_token');
    if (token != null) {
      setState(() {
        _accessToken = token;
        _isSpotifyLoggedIn = true;
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            FutureBuilder<User?>(
              future: FirebaseAuth.instance.authStateChanges().first,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    color: const Color(0xFFE46E86),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    color: const Color(0xFFE46E86),
                    child: const Center(
                      child: Text(
                        'Error loading user data',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                final user = snapshot.data!;
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _getUserData(user.email!),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        color: const Color(0xFFE46E86),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        color: const Color(0xFFE46E86),
                        child: UserAccountsDrawerHeader(
                          accountName: Text(
                            'Welcome ${user.displayName ?? 'User Name'}',
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          accountEmail: Text(
                            user.email ?? 'user@example.com',
                            style: const TextStyle(
                                fontSize: 16.0, color: Colors.white),
                          ),
                          currentAccountPicture: CircleAvatar(
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE46E86),
                          ),
                        ),
                      );
                    }

                    final userData = userSnapshot.data!;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      color: const Color(0xFFE46E86),
                      child: UserAccountsDrawerHeader(
                        accountName: Text(
                          'Welcome ${userData['name'] ?? 'User Name'}',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        accountEmail: Text(
                          userData['email'] ?? user.email!,
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.white),
                        ),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: userData['imageUrl'] != null
                              ? NetworkImage(userData['imageUrl'])
                              : null,
                          child: userData['imageUrl'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE46E86),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const TabBar(
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Settings'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
            Expanded(
              child: Container(
                color: const Color(0xFF1E1E1E),
                child: TabBarView(
                  children: [
                    GeneralTab(),
                    SettingsTab(),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
              leading: const Icon(Icons.logout, color: Colors.white),
              onTap: () async {
                bool confirmed = await _showConfirmationDialog(context, 'Logout', 'Are you sure you want to logout?');
                if (confirmed) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                }
              },
            ),
            ListTile(
              title: Text(
                _isSpotifyLoggedIn ? 'Logged in to Spotify' : 'Login with Spotify',
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
              leading: const Icon(Icons.music_note, color: Colors.white),
              onTap: _authenticateWithSpotify,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _authenticateWithSpotify() async {
    final spotifyAuth = SpotifyAuth(
      clientId: '3292deb19af240a885d7fd118ca150c2',
      clientSecret: '270d5d708804496f9f4d777a57021c28',
      redirectUri: 'momofy3://callback',
      scopes: ['user-read-email', 'playlist-read-private'],
    );

    final accessToken = await spotifyAuth.authenticate();

    if (accessToken != null) {
      setState(() {
        _accessToken = accessToken;
        _isSpotifyLoggedIn = true;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_access_token', accessToken);
      await prefs.setString('spotifyAuthAlbum', accessToken); // Save in album tab
      await prefs.setString('spotifyAuthArtist', accessToken); // Save in artist tab
      await prefs.setString('spotifyAuthSong', accessToken); // Save in song tab
      await prefs.setString('spotifyAuth', accessToken); // Save in home page

      final spotifyService = SpotifyService(accessToken);
      final userProfile = await spotifyService.fetchUserProfile();
      final playlists = await spotifyService.fetchPlaylists();

      setState(() {
        _userProfile = userProfile;
        _playlists = playlists;
      });
    } else {
      // Handle authentication error
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}

class GeneralTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildListTile(
            'Songs', Icons.music_note, context, SongsPage(initialIndex: 0)),
        _buildListTile(
            'Albums', Icons.album, context, SongsPage(initialIndex: 1)),
        _buildListTile(
            'Artists', Icons.person, context, SongsPage(initialIndex: 2)),
        _buildListTile('Playlists', Icons.playlist_play, context,
            SongsPage(initialIndex: 3)),
      ],
    );
  }

  Widget _buildListTile(
      String title, IconData icon, BuildContext context, Widget? page) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16.0, color: Colors.white),
      ),
      leading: Icon(icon, color: Colors.white),
      onTap: page != null
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
          : null,
    );
  }
}

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildListTile('Your Profile', Icons.person, context, SettingsPage()),
        _buildListTile('Update Account Info', Icons.update, context, UpdateAccountInfoPage()),
        _buildListTile('Logout', Icons.logout, context, null, _logout),
        _buildListTile('Delete Account', Icons.delete, context, null, _deleteAccount),
      ],
    );
  }

  Widget _buildListTile(String title, IconData icon, BuildContext context, Widget? page, [Function? onTap]) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16.0, color: Colors.white),
      ),
      leading: Icon(icon, color: Colors.white),
      onTap: page != null
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
          : onTap != null
          ? () => onTap(context)
          : null,
    );
  }

  void _logout(BuildContext context) async {
    bool confirmed = await _showConfirmationDialog(context, 'Logout', 'Are you sure you want to logout?');
    if (confirmed) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  void _deleteAccount(BuildContext context) async {
    bool confirmed = await _showConfirmationDialog(context, 'Delete Account', 'Are you sure you want to delete your account? This action is irreversible.');
    if (confirmed) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}
