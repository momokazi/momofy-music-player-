import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your splash screen content, such as logo or animation
            Image.asset('assets/splash_image.png'),
            SizedBox(height: 14),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
