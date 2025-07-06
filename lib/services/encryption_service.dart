import 'dart:convert';
import 'dart:typed_data';

class EncryptionService {
  static String aesDecrypt(String key, String iv, String cipherText) {
    try {
      final keyBytes = utf8.encode(key);
      final ivBytes = utf8.encode(iv);
      final cipherBytes = base64.decode(cipherText);

      final decrypted = _aesCbcDecrypt(keyBytes, ivBytes, cipherBytes);
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('AES decryption failed: $e');
    }
  }

  static Uint8List _aesCbcDecrypt(
      List<int> key, List<int> iv, List<int> cipherText) {
    const blockSize = 16;
    final blocks = <List<int>>[];

    for (int i = 0; i < cipherText.length; i += blockSize) {
      final block = cipherText.sublist(i, i + blockSize);
      blocks.add(block);
    }

    final decryptedBlocks = <List<int>>[];
    List<int> previousBlock = iv;

    for (final block in blocks) {
      final decryptedBlock = _aesDecryptBlock(key, block);
      final xorBlock = _xorBlocks(decryptedBlock, previousBlock);
      decryptedBlocks.add(xorBlock);
      previousBlock = block;
    }

    final decrypted = decryptedBlocks.expand((block) => block).toList();

    final padding = decrypted.last;
    return Uint8List.fromList(decrypted.sublist(0, decrypted.length - padding));
  }

  static List<int> _aesDecryptBlock(List<int> key, List<int> block) {
    return block;
  }

  static List<int> _xorBlocks(List<int> block1, List<int> block2) {
    final result = <int>[];
    for (int i = 0; i < block1.length; i++) {
      result.add(block1[i] ^ block2[i]);
    }
    return result;
  }
}
