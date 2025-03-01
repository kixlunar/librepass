/*    
    Copyright (C) 2025  kixlunar

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

// Generate a 32-byte key synchronously using PBKDF2
Map<String, String> generateKey(String userkey) {
  // Generate a random salt
  final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)));

  // PBKDF2 with SHA-256
  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(salt, 10000, 32)); // 10000 iterations, 32-byte key

  final passwordBytes = utf8.encode(userkey);
  final keyBytes = pbkdf2.process(Uint8List.fromList(passwordBytes));

  return {
    'key': base64Encode(keyBytes), // Base64-encoded key
    'salt': base64Encode(salt), // Base64-encoded salt
  };
}

List<String> encryptJsonString(String userkey, String jsonString) {
  // Generate key and salt
  final keyResult = generateKey(userkey);
  final keyBase64 = keyResult['key']!;
  final saltBase64 = keyResult['salt']!;

  // Decode key to bytes for AES
  final keyBytes = base64Decode(keyBase64);
  final key = Key(keyBytes); // Key.fromUtf8 expects raw bytes, not base64

  // Generate IV
  final iv = IV.fromSecureRandom(12);

  // Encrypt
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  final encrypted = encrypter.encrypt(jsonString, iv: iv);

  // Return IV, ciphertext, and salt (needed for decryption)
  return [
    iv.base64, // IV
    encrypted.base64, // Ciphertext
    saltBase64, // Salt
  ];
}

String decryptJsonString(String userkey, String ivBase64,
    String cipherTextBase64, String saltBase64) {
  // Re-derive the key using the stored salt
  final salt = base64Decode(saltBase64);
  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(salt, 10000, 32)); // Same parameters as encryption

  final passwordBytes = utf8.encode(userkey);
  final keyBytes = pbkdf2.process(Uint8List.fromList(passwordBytes));
  final key = Key(keyBytes);

  // Decode IV and ciphertext
  final iv = IV.fromBase64(ivBase64);
  final cipherTextBytes = base64Decode(cipherTextBase64);

  // Decrypt
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  return encrypter.decrypt(Encrypted(cipherTextBytes), iv: iv);
}
