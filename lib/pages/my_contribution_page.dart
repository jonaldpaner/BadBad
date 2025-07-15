import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class MyContributionPage extends StatefulWidget {
  const MyContributionPage({super.key});

  @override
  State<MyContributionPage> createState() => _MyContributionPageState();
}

class _MyContributionPageState extends State<MyContributionPage> {
  final List<Map<String, String>> contributions = [];
  final Color primaryColor = const Color(0xFF219EBC);
  final AudioPlayer _player = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  int? currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadUserPhrases();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _loadUserPhrases() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final uri = Uri.parse(
      'https://electric-dassie-vertically.ngrok-free.app/user-phrases?user=${user.uid}',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final List<Map<String, String>> loaded = data.map<Map<String, String>>((item) {
          return {
            'id': item['id'].toString(),
            'ata': item['ata_phrase'] ?? '',
            'english': item['eng_phrase'] ?? '',
            'status': item['status'] ?? '',
            'audio':
            'https://electric-dassie-vertically.ngrok-free.app/audio-by-url?audio_url=${Uri.encodeComponent(item['audio_url'] ?? '')}',
          };
        }).toList();
        setState(
          () => contributions
            ..clear()
            ..addAll(loaded),
        );
      } else {
        debugPrint('Failed to fetch phrases: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error loading phrases: $e');
    }
  }

  void _showAddOrEditDialog({int? editIndex}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please log in to contribute phrases.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF219EBC)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final isEditing = editIndex != null;
    final ataController = TextEditingController(
      text: isEditing ? contributions[editIndex!]['ata'] : '',
    );
    final englishController = TextEditingController(
      text: isEditing ? contributions[editIndex!]['english'] : '',
    );
    String? audioPath = isEditing ? null : null;
    String? existingAudioName;
    if (isEditing) {
      final audioUrl = contributions[editIndex!]['audio'] ?? '';
      final uri = Uri.parse(audioUrl);
      final decodedAudioUrl = Uri.decodeFull(uri.queryParameters['audio_url'] ?? '');
      existingAudioName = Uri.parse(decodedAudioUrl).pathSegments.last;
    }

    final _formKey = GlobalKey<FormState>();
    bool isRecording = false;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
        bool showAudioError = false;

        // Timer-related state
        bool isRecording = false;
        Duration recordingDuration = Duration.zero;
        Timer? recordingTimer;

        return StatefulBuilder(
          builder: (context, setState) {
            final AudioPlayer previewPlayer = AudioPlayer();
            bool isPreviewPlaying = false;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'Edit Phrase' : 'Add New Phrase',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: ataController,
                              cursorColor: primaryColor,
                              decoration: InputDecoration(
                                labelText: 'Ata Manobo',
                                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: textColor.withOpacity(0.4)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                              ),
                              validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: englishController,
                              cursorColor: primaryColor,
                              decoration: InputDecoration(
                                labelText: 'English',
                                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: textColor.withOpacity(0.4)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                              ),
                              validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.audiotrack_rounded),
                                    label: const Text("Attach Audio"),
                                    onPressed: () async {
                                      final status = await Permission.audio.request();
                                      if (status.isGranted) {
                                        final result = await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['mp3', 'wav', 'm4a'],
                                        );
                                        if (result != null && result.files.single.path != null) {
                                          setState(() {
                                            audioPath = result.files.single.path!;
                                            showAudioError = false;
                                          });
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Audio permission denied')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text("or"),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                                    label: Text(
                                      isRecording
                                          ? '${recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
                                          : 'Record',
                                    ),
                                    onPressed: () async {
                                      final micStatus = await Permission.microphone.request();
                                      if (!micStatus.isGranted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Microphone permission denied')),
                                        );
                                        return;
                                      }

                                      if (!isRecording) {
                                        final tempDir = await getTemporaryDirectory();
                                        final recordPath =
                                            '${tempDir.path}/recorded_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                        await _recorder.startRecorder(
                                          toFile: recordPath,
                                          codec: Codec.aacMP4,
                                        );
                                        audioPath = null;
                                        isRecording = true;
                                        recordingDuration = Duration.zero;

                                        recordingTimer?.cancel();
                                        recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                                          setState(() {
                                            recordingDuration += const Duration(seconds: 1);
                                          });
                                        });

                                        setState(() {});
                                      } else {
                                        final path = await _recorder.stopRecorder();
                                        audioPath = path;
                                        isRecording = false;

                                        recordingTimer?.cancel();
                                        recordingTimer = null;

                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              audioPath != null
                                  ? path.basename(audioPath!)
                                  : (existingAudioName ?? 'No audio selected or recorded'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: showAudioError ? Colors.red : null,
                                fontWeight: showAudioError ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (audioPath != null)
                              ElevatedButton.icon(
                                icon: Icon(isPreviewPlaying ? Icons.pause : Icons.play_arrow),
                                label: Text(isPreviewPlaying ? 'Pause Recording' : 'Play Recording'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade800,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  if (isPreviewPlaying) {
                                    await previewPlayer.pause();
                                    setState(() => isPreviewPlaying = false);
                                  } else {
                                    try {
                                      await previewPlayer.setFilePath(audioPath!);
                                      await previewPlayer.play();
                                      setState(() => isPreviewPlaying = true);

                                      previewPlayer.playerStateStream.listen((state) {
                                        if (state.processingState == ProcessingState.completed) {
                                          setState(() => isPreviewPlaying = false);
                                        }
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error playing recording: $e')),
                                      );
                                    }
                                  }
                                },
                              ),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            previewPlayer.dispose();
                            recordingTimer?.cancel();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          onPressed: () {
                            final isValid = _formKey.currentState!.validate();
                            final isAudioValid = audioPath != null;
                            if (!isAudioValid) {
                              setState(() => showAudioError = true);
                            }
                            if (isValid && isAudioValid) {
                              recordingTimer?.cancel();
                              Navigator.of(context).pop({
                                'user': user.uid,
                                'ata': ataController.text.trim(),
                                'english': englishController.text.trim(),
                                'audio': audioPath!,
                              });
                            }
                          },
                          child: Text(
                            isEditing ? 'Save' : 'Add',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );


    if (result != null) {
      final isEditing = editIndex != null;
      final id = isEditing ? contributions[editIndex!]['id'] : null;
      await _uploadPhraseToAPI(
        id: id,
        user: result['user']!,
        ata: result['ata']!,
        english: result['english']!,
        audioPath: result['audio']!,
      );
      await _loadUserPhrases();
    }
  }

  Future<void> _uploadPhraseToAPI({
    required String? id,
    required String user,
    required String ata,
    required String english,
    required String audioPath,
  }) async {
    final isEditing = id != null;
    final uri = Uri.parse(
      isEditing
          ? "https://electric-dassie-vertically.ngrok-free.app/update-phrase"
          : "https://electric-dassie-vertically.ngrok-free.app/add-phrase",
    );

    final request = http.MultipartRequest('POST', uri);
    if (isEditing) request.fields['id'] = id!;
    request.fields['user'] = user;
    request.fields['ata_phrase'] = ata;
    request.fields['eng_phrase'] = english;

    if (audioPath.isNotEmpty && File(audioPath).existsSync()) {
      final mimeType = lookupMimeType(audioPath) ?? 'audio/mpeg';
      final mimeSplit = mimeType.split('/');
      final audioFile = File(audioPath);
      final fileName = path.basename(audioFile.path);
      request.files.add(
        http.MultipartFile(
          'audio',
          audioFile.readAsBytes().asStream(),
          audioFile.lengthSync(),
          filename: fileName,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        ),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        debugPrint("Upload Success: $responseBody");
      } else {
        debugPrint("Upload Failed (${response.statusCode}): $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload: $responseBody")),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error uploading: $e")));
    }
  }

  Future<void> _deletePhrase(int index) async {
    final id = contributions[index]['id'];
    final uri = Uri.parse(
      "https://electric-dassie-vertically.ngrok-free.app/delete-phrase?id=$id",
    );

    try {
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        setState(() => contributions.removeAt(index));
        debugPrint("✅ Deleted phrase $id");
      } else {
        debugPrint("❌ Failed to delete: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("❌ Delete error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete error: $e")));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _playAudio(String url, int index) async {
    try {
      setState(() => currentlyPlayingIndex = index);
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      _player.playerStateStream
          .firstWhere(
            (state) => state.processingState == ProcessingState.completed,
          )
          .then((_) {
            setState(() => currentlyPlayingIndex = null);
          });
    } catch (e) {
      setState(() => currentlyPlayingIndex = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play audio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showAddOrEditDialog(),
        tooltip: 'Add Phrase',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: contributions.isEmpty
          ? Center(
              child: Text(
                'You have not added any phrases yet.',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contributions.length,
              itemBuilder: (context, index) {
                final phrase = contributions[index];
                final hasAudio = phrase.containsKey('audio');
                return Card(
                  color: currentlyPlayingIndex == index
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: theme.brightness == Brightness.dark ? 2 : 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    title: Text(
                      phrase['ata'] ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phrase['english'] ?? '',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${phrase['status']?.toUpperCase() ?? 'UNKNOWN'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(phrase['status']),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasAudio)
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, size: 20),
                            tooltip: 'Play',
                            onPressed: () =>
                                _playAudio(phrase['audio']!, index),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showAddOrEditDialog(editIndex: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => _deletePhrase(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
