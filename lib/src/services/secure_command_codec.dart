import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

class SecureCommandCodec {
  SecureCommandCodec({String? passphrase})
      : _passphrase = (passphrase ?? const String.fromEnvironment('FLOWMATIC_COMMAND_KEY')).trim();

  final String _passphrase;

  bool get hasConfiguredKey => _passphrase.isNotEmpty;

  Future<Map<String, dynamic>> encode(Map<String, dynamic> payload) async {
    final canonicalJson = _canonicalize(payload);
    if (!hasConfiguredKey) {
      debugPrint('FLOWMATIC_COMMAND_KEY not set. Falling back to signed plaintext commands.');
      final digest = await Sha256().hash(utf8.encode(canonicalJson));
      return {
        'mode': 'SIGNED_PLAINTEXT',
        'payload': payload,
        'sha256': base64Encode(digest.bytes),
      };
    }

    final keyBytes = (await Sha256().hash(utf8.encode(_passphrase))).bytes;
    final secretKey = SecretKey(keyBytes);
    final algorithm = AesGcm.with256bits();

    final secretBox = await algorithm.encrypt(
      utf8.encode(canonicalJson),
      secretKey: secretKey,
    );

    final cipherText = <int>[...secretBox.cipherText, ...secretBox.mac.bytes];

    return {
      'mode': 'AES_GCM_256',
      'payloadCiphertext': base64Encode(cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'schema': 1,
    };
  }

  String _canonicalize(Map<String, dynamic> payload) {
    final sortedEntries = payload.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final ordered = <String, dynamic>{
      for (final entry in sortedEntries)
        entry.key: entry.value is Map<String, dynamic> ? _normalizeNested(entry.value as Map<String, dynamic>) : entry.value,
    };
    return jsonEncode(ordered);
  }

  Map<String, dynamic> _normalizeNested(Map<String, dynamic> payload) {
    final sortedEntries = payload.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in sortedEntries) entry.key: entry.value};
  }
}
