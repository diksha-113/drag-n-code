// lib/vm/util/uid.dart
import 'dart:math';

/// Returns a simple unique ID string.
String uid() {
  final random = Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final randomValue = random.nextInt(1 << 32);
  return 'id_${timestamp}_$randomValue';
}

/// Generates a random 16-character alphanumeric UID.
String generateUid() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
}
