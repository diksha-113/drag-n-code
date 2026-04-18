import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/workspace.dart';

class SpritePanel extends StatefulWidget {
  final List<String> spriteAssets;
  final List<Sprite> engineSprites;

  const SpritePanel({
    super.key,
    required this.spriteAssets,
    required this.engineSprites,
  });

  @override
  _SpritePanelState createState() => _SpritePanelState();
}

class _SpritePanelState extends State<SpritePanel> {
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Automatically focus for keyboard events
    _focusNode.requestFocus();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.delete) {
      setState(() {
        // Remove the currently selected sprite
        widget.engineSprites.removeWhere((s) => s.isSelected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKey,
        child: Column(
          children: [
            // Blue header
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context), // back to editor
                    child: SvgPicture.asset(
                      'assets/images/back_arrow.svg',
                      width: 28,
                      height: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Choose a Sprite',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Sprites grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.spriteAssets.length,
                itemBuilder: (context, index) {
                  final spritePath = widget.spriteAssets[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // Deselect all sprites first
                        for (var s in widget.engineSprites) {
                          s.isSelected = false;
                        }

                        // Add or select the sprite
                        final existingIndex = widget.engineSprites
                            .indexWhere((s) => s.assetPath == spritePath);

                        if (existingIndex != -1) {
                          widget.engineSprites[existingIndex].isSelected = true;
                          widget.engineSprites[existingIndex].visible = true;
                        } else {
                          widget.engineSprites.add(Sprite(
                            assetPath: spritePath,
                            x: 50,
                            y: 50,
                            direction: 90,
                            visible: true,
                            isSelected: true,
                          ));
                        }

                        // Optional: show blocks for selected sprite
                        print("$spritePath selected -> show blocks editor");
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: widget.engineSprites.any((s) =>
                                s.assetPath == spritePath && s.isSelected)
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: spritePath.endsWith('.svg')
                            ? SvgPicture.asset(spritePath)
                            : Image.asset(spritePath),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
