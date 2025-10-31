import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:smart_care/config/encryption_key.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  final AesGcm _cipher = AesGcm.with256bits();

  /// Criptografa um Map<String, dynamic> e retorna um envelope com os dados criptografados
  /// 
  /// Retorna um Map com a estrutura:
  /// - 'v': versão do envelope (int)
  /// - 'alg': algoritmo usado (String)
  /// - 'nonce': nonce em base64 (String)
  /// - 'ciphertext': texto criptografado em base64 (String)
  /// - 'mac': MAC em base64 (String)
  /// - 'ts': timestamp UTC em ISO8601 (String, opcional)
  Future<Map<String, dynamic>> encrypt(Map<String, dynamic> data) async {
    final Uint8List keyBytes = EncryptionKeyConfig.keyBytes;
    final SecretKey secretKey = SecretKey(keyBytes);

    final List<int> plainBytes = utf8.encode(jsonEncode(data));
    final List<int> nonce = _generateSecureRandomBytes(12); // GCM nonce 96 bits
    
    final SecretBox box = await _cipher.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return <String, dynamic>{
      'v': 1,
      'alg': 'AES-GCM-256',
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Descriptografa um envelope e retorna os dados originais
  /// 
  /// [envelope] deve conter:
  /// - 'nonce': nonce em base64 (String)
  /// - 'ciphertext': texto criptografado em base64 (String)
  /// - 'mac': MAC em base64 (String)
  /// 
  /// Retorna null se a descriptografia falhar (dados corrompidos ou inválidos)
  Future<Map<String, dynamic>?> decrypt(Map<String, dynamic> envelope) async {
    try {
      final Uint8List keyBytes = EncryptionKeyConfig.keyBytes;
      final SecretKey secretKey = SecretKey(keyBytes);

      final List<int> nonce = base64Decode(envelope['nonce'] as String);
      final List<int> cipherText = base64Decode(envelope['ciphertext'] as String);
      final List<int> macBytes = base64Decode(envelope['mac'] as String);
      
      final SecretBox box = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final List<int> clearBytes = await _cipher.decrypt(
        box,
        secretKey: secretKey,
      );
      
      final String jsonString = utf8.decode(clearBytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Silenciosamente retorna null em caso de erro
      // (dados corrompidos, formato inválido, etc)
      return null;
    }
  }

  /// Gera bytes aleatórios seguros
  List<int> _generateSecureRandomBytes(int length) {
    final Random rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }
}
