import 'dart:io';
import 'package:crypto/crypto.dart';

/// A simple [Sink<Digest>] that stores the single digest result.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

/// Computes the first 8 hex characters of the SHA-256 hash of a file,
/// reading it in streaming chunks to avoid loading the entire file into memory.
Future<String> computeFileHash(String filePath) async {
  final sink = _DigestSink();
  final input = sha256.startChunkedConversion(sink);
  await for (final chunk in File(filePath).openRead()) {
    input.add(chunk);
  }
  input.close();
  return sink.value!.toString().substring(0, 8);
}
