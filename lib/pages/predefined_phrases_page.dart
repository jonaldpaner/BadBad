import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';


class PredefinedPhrasesPage extends StatefulWidget {
  const PredefinedPhrasesPage({super.key});

  @override
  State<PredefinedPhrasesPage> createState() => _PredefinedPhrasesPageState();
}

class _PredefinedPhrasesPageState extends State<PredefinedPhrasesPage> {
  List<Map<String, dynamic>> phrases = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String baseUrl = 'https://electric-dassie-vertically.ngrok-free.app';
  int? currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    fetchPhrases();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchPhrases() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/all-phrases'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          phrases = data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load phrases');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBar(context, theme),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : phrases.isEmpty
          ? const Center(child: Text('No phrases found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return Card(
              color: currentlyPlayingIndex == index
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: theme.brightness == Brightness.dark ? 2 : 4,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              title: Text(
                phrase['ata_phrase'] ?? '',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                phrase['eng_phrase'] ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                ),
              ),
              trailing: phrase['audio_url'] != null && phrase['audio_url'].toString().isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.volume_up_rounded,  color: theme.iconTheme.color,),
                onPressed: () async {
                  final audioUrl = '$baseUrl/audio-by-url?audio_url=${Uri.encodeComponent(phrase['audio_url'])}';
                  print('Playing audio from: $audioUrl');

                  try {
                    setState(() {
                      currentlyPlayingIndex = index;

                    });

                    await _audioPlayer.play(UrlSource(audioUrl));

                    // Wait for playback to complete
                    _audioPlayer.onPlayerComplete.listen((event) {
                      setState(() {
                        currentlyPlayingIndex = null;
                      });
                    });

                  } catch (e) {
                    setState(() {
                      currentlyPlayingIndex = null;
                    });
                    print('Audio playback error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Audio failed: $e'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },

              )
                  : null,
            ),
          );
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation ?? 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: theme.iconTheme.color,
          size: 25,
        ),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
      title: Text(
        'Learn',
        style: theme.appBarTheme.titleTextStyle,
      ),
      centerTitle: true,
    );
  }
}
