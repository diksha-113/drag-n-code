import 'dart:convert';
import 'dart:typed_data';

class Base64Util {
  static Uint8List base64ToUint8Array(String base64) {
    return base64Decode(base64);
  }

  static String uint8ArrayToBase64(Uint8List array) {
    return base64Encode(array);
  }

  static String arrayBufferToBase64(ByteBuffer buffer) {
    final bytes = Uint8List.view(buffer);
    return base64Encode(bytes);
  }
}
