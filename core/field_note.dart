import 'package:flutter/material.dart';

typedef NoteSelectedCallback = void Function(int midiNote);

class FieldNotePicker extends StatefulWidget {
  final int initialNote;
  final NoteSelectedCallback? onNoteSelected;

  const FieldNotePicker({
    super.key,
    this.initialNote = 60,
    this.onNoteSelected,
  });

  @override
  State<FieldNotePicker> createState() => _FieldNotePickerState();
}

class _FieldNotePickerState extends State<FieldNotePicker> {
  static const int maxNote = 130;
  static const int numWhiteKeys = 8;
  static const double whiteKeyWidth = 40;
  static const double whiteKeyHeight = 72;
  static const double blackKeyWidth = 32;
  static const double blackKeyHeight = 40;
  static const double keyRadius = 6;

  static const List<Map<String, dynamic>> keyInfo = [
    {'name': 'C', 'pitch': 0},
    {'name': 'C#', 'pitch': 1, 'isBlack': true},
    {'name': 'D', 'pitch': 2},
    {'name': 'Eb', 'pitch': 3, 'isBlack': true},
    {'name': 'E', 'pitch': 4},
    {'name': 'F', 'pitch': 5},
    {'name': 'F#', 'pitch': 6, 'isBlack': true},
    {'name': 'G', 'pitch': 7},
    {'name': 'G#', 'pitch': 8, 'isBlack': true},
    {'name': 'A', 'pitch': 9},
    {'name': 'Bb', 'pitch': 10, 'isBlack': true},
    {'name': 'B', 'pitch': 11},
  ];

  int selectedNote = 60;
  int displayedOctave = 5;

  @override
  void initState() {
    super.initState();
    selectedNote = widget.initialNote;
    displayedOctave = selectedNote ~/ 12;
  }

  void _selectNote(int pitch) {
    setState(() {
      selectedNote = displayedOctave * 12 + pitch;
      if (selectedNote > maxNote) selectedNote = maxNote;
    });
    widget.onNoteSelected?.call(selectedNote);
  }

  void _changeOctave(int delta) {
    setState(() {
      displayedOctave += delta;
      if (displayedOctave < 0) displayedOctave = 0;
      if (displayedOctave * 12 > maxNote) displayedOctave = maxNote ~/ 12;
      int noteInOctave = selectedNote % 12;
      selectedNote = displayedOctave * 12 + noteInOctave;
      if (selectedNote > maxNote) selectedNote = maxNote;
    });
    widget.onNoteSelected?.call(selectedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top menu with octave buttons and note display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () => _changeOctave(-1),
            ),
            Text(
              '${keyInfo[selectedNote % 12]['name']} ($selectedNote)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () => _changeOctave(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Piano keys
        SizedBox(
          width: numWhiteKeys * whiteKeyWidth,
          height: whiteKeyHeight,
          child: Stack(
            children: [
              // White keys
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(numWhiteKeys, (i) {
                  return GestureDetector(
                    onTap: () => _selectNote(i),
                    child: Container(
                      width: whiteKeyWidth,
                      height: whiteKeyHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(keyRadius),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Black keys
              Positioned(
                top: 0,
                left: 0,
                child: Row(
                  children: List.generate(numWhiteKeys, (i) {
                    int pitch = i * 2 + 1;
                    if (pitch >= keyInfo.length ||
                        !keyInfo[pitch].containsKey('isBlack')) {
                      return const SizedBox(
                        width: whiteKeyWidth,
                        height: blackKeyHeight,
                      );
                    }
                    return GestureDetector(
                      onTap: () => _selectNote(keyInfo[pitch]['pitch']),
                      child: Container(
                        width: blackKeyWidth,
                        height: blackKeyHeight,
                        margin: EdgeInsets.only(
                          left: whiteKeyWidth - blackKeyWidth / 2,
                          right: whiteKeyWidth / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(keyRadius),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
