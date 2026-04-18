import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ===== SPRITE CONTROLLER =====
class SpriteController extends ChangeNotifier {
  double x = 0;
  double y = 0;
  String costume = 'assets/sprites/cat.svg';
  String speech = '';

  void moveSteps(double steps) {
    x += steps;
    notifyListeners();
  }

  void goTo(double newX, double newY) {
    x = newX;
    y = newY;
    notifyListeners();
  }

  void say(String message, {int duration = 2}) {
    speech = message;
    notifyListeners();
    Future.delayed(Duration(seconds: duration), () {
      speech = '';
      notifyListeners();
    });
  }

  void changeCostume(String newCostume) {
    costume = newCostume;
    notifyListeners();
  }

  void reset() {
    x = 0;
    y = 0;
    speech = '';
    notifyListeners();
  }
}

// ===== STAGE WIDGET =====
class StageWidget extends StatelessWidget {
  final SpriteController controller;
  final VoidCallback? onGreenFlag;
  final VoidCallback? onStopAll;

  const StageWidget({
    super.key,
    required this.controller,
    this.onGreenFlag,
    this.onStopAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Green Flag & Stop Buttons
        Row(
          children: [
            GestureDetector(
              onTap: onGreenFlag,
              child: SizedBox(
                width: 34,
                height: 34,
                child: SvgPicture.asset('assets/green-flag.svg'),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onStopAll,
              child: SizedBox(
                width: 34,
                height: 34,
                child: SvgPicture.asset('assets/icon--stop-all.svg'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Stage Area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      left: controller.x,
                      top: controller.y,
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            controller.costume,
                            width: 120,
                          ),
                          if (controller.speech.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 4)
                                ],
                              ),
                              child: Text(controller.speech),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
