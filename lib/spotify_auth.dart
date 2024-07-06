import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpotifyAuth {
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final List<String> scopes;

  SpotifyAuth({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.scopes,
  });
  Future<String?> getAccessToken() async {
    return await authenticate();
  }
  Future<String?> authenticate() async {
    final authUrl = Uri.https(
      'accounts.spotify.com',
      '/authorize',
      {
        'response_type': 'code',
        'client_id': clientId,
        'scope': scopes.join(' '),
        'redirect_uri': redirectUri,
      },
    ).toString();

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: redirectUri.split(':').first,
    );

    final code = Uri.parse(result).queryParameters['code'];

    if (code != null) {
      final tokenUrl = Uri.https('accounts.spotify.com', '/api/token');
      final response = await http.post(
        tokenUrl,
        headers: {
          'Authorization':
          'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      final jsonResponse = json.decode(response.body);
      return jsonResponse['access_token'];
    }

    return null;
  }
}
