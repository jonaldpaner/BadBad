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

  // Category selection state
  String? selectedCategory;
  final List<String> availableCategories = [
    'Greetings',
    'Family & People',
    'Health & Emergency',
    'Food & Eating',
    'Uncategorized',
  ];

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

  Future<bool> submitFeedback(String phraseId, String user, String feedbackText) async {
    final url = Uri.parse('$baseUrl/add-feedback');
    final Map<String, dynamic> payload = {
      'phrase_id': int.tryParse(phraseId),
      'user': user,
      'feedback': feedbackText,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Feedback submitted successfully');
        return true;
      } else {
        print('❌ Failed to submit feedback: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Error submitting feedback: $e');
      return false;
    }
  }

  void showFeedbackDialog(BuildContext context, Map<String, dynamic> phrase) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Phrase Feedback'),
          content: TextField(
            controller: feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Let us know what needs fixing...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel',style: TextStyle(color: Color(0xFF219EBC)),),
            ),
            ElevatedButton(
              onPressed: () async {
                final String feedback = feedbackController.text.trim();

                if (feedback.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context); // 👈 capture first!

                  Navigator.of(context).pop(); // Close dialog

                  final String phraseId = phrase['id'].toString();
                  final String user = phrase['user'] ?? 'guest_user';

                  final success = await submitFeedback(phraseId, user, feedback);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Thanks for your feedback!'
                          : 'Feedback failed to submit. Try again.'),
                      duration: const Duration(milliseconds: 800 ),
                    ),
                  );
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Color(0xFF219EBC)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchPhrases({String? category}) async {
    setState(() => isLoading = true);
    try {
      final url = category == null
          ? '$baseUrl/all-phrases'
          : '$baseUrl/category-phrases?category=${Uri.encodeComponent(category)}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          phrases = data
              .where((item) => item['status'] == 'active')
              .map((item) => item as Map<String, dynamic>)
              .toList();
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

  String getCategory(Map<String, dynamic> phrase) {
    final text = (phrase['eng_phrase'] ?? '').toString().toLowerCase();

    if (text.contains('hello') || text.contains('hi')) return 'Greetings';
    if (text.contains('mother') || text.contains('father')) return 'Family & People';
    if (text.contains('help') || text.contains('emergency') || text.contains('sick')) return 'Health & Emergency';
    if (text.contains('eat') || text.contains('hungry') || text.contains('drink')) return 'Food & Eating';

    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBar(context, theme),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedCategory == null
          ? buildCategorySelection(theme)
          : buildPhraseList(theme),
    );
  }

  Widget buildCategorySelection(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: availableCategories.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: () async {
              setState(() {
                selectedCategory = category;
              });
              await fetchPhrases(category: category);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    // Category text
                    Expanded(
                      child: Text(
                        category,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );

      }).toList(),
    );
  }

  Widget buildPhraseList(ThemeData theme) {
    final filtered = phrases;

    return filtered.isEmpty
        ? const Center(child: Text('No phrases found in this category.'))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final phrase = filtered[index];
        return Card(
          color: currentlyPlayingIndex == index
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: theme.brightness == Brightness.dark ? 2 : 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Text content (Ata + English phrase)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase['ata_phrase'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        phrase['eng_phrase'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Feedback button
                Container(
                  height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child: IconButton(
                    icon: Icon(Icons.feedback_outlined, color: theme.iconTheme.color),
                    onPressed: () => showFeedbackDialog(context, phrase),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(width: 4),
                // Audio button (only if audio URL is available)
                if (phrase['audio_url'] != null && phrase['audio_url'].toString().isNotEmpty)
                  Container(
                    height: 40,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: Icon(Icons.volume_up_rounded, color: theme.iconTheme.color),
                      onPressed: () async {
                        final audioUrl =
                            '$baseUrl/audio-by-url?audio_url=${Uri.encodeComponent(phrase['audio_url'])}';
                        print('Playing audio from: $audioUrl');
                        try {
                          setState(() {
                            currentlyPlayingIndex = index;
                          });
                          await _audioPlayer.play(UrlSource(audioUrl));
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
          selectedCategory == null
              ? Icons.arrow_back_ios_new_rounded
              : Icons.arrow_back_ios_new_rounded,
          color: theme.iconTheme.color,
          size: 25,
        ),
        onPressed: () {
          if (selectedCategory == null) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              selectedCategory = null;
              currentlyPlayingIndex = null;
            });
          }
        },
        tooltip: 'Back',
      ),
      title: Text(
        selectedCategory == null ? 'Select Category' : selectedCategory!,
        style: theme.appBarTheme.titleTextStyle,
      ),
      centerTitle: true,
    );
  }
}
