import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Big Dict Energy was built by Patrick because he was too impatient to wait for the next NYT Spelling Bee to come out.\n\n',
              style: TextStyle(fontSize: 16),
            ),
            InkWell(
              onTap: () => _launchUrl('https://buymeacoffee.com/patricknoonan'),
              child: const Text(
                'Buy Me A Coffee',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'or',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchUrl('https://x.com/patricknoonan89'),
              child: const Text(
                'follow on X',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Special shoutout to Dwyl and his ',
                  style: TextStyle(fontSize: 16),
                ),
                InkWell(
                  onTap: () =>
                      _launchUrl('https://github.com/dwyl/english-words'),
                  child: const Text(
                    'dictionary',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
