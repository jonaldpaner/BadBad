import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String leftLanguage = 'English';
  String rightLanguage = 'Ata Manobo';

  void swapLanguages() {
    setState(() {
      final temp = leftLanguage;
      leftLanguage = rightLanguage;
      rightLanguage = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => print('$leftLanguage selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(leftLanguage),
                ),
              ),
              const SizedBox(width: 80),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => print('$rightLanguage selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(rightLanguage),
                ),
              ),
            ],
          ),

          Positioned(
            child: Material(
              color: Colors.grey[850],
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                onPressed: swapLanguages,
                tooltip: 'Swap Languages',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
