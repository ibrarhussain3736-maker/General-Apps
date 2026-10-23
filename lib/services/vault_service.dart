import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// PINs, keys and AES-256-GCM file encryption. Keys are kept in Android Keystore-backed storage.
class VaultService {
  static const _s = FlutterSecureStorage();
  static final _rng = Random.secure();

  static String _rand(int n) => base64UrlEncode(List.generate(n, (_) => _rng.nextInt(256)));

  static String _hash(String pin, String salt) {
    List<int> d = utf8.encode('$salt:$pin');
    for (var i = 0; i < 5000; i++) {
      d = sha256.convert(d).bytes;
    }
    return base64Encode(d);
  }

  // ---- PINs ('real' and 'fake') ----
  static Future<bool> hasPin(String which) async => await _s.read(key: '${which}_hash') != null;

  static Future<void> setPin(String which, String pin) async {
    final salt = _rand(16);
    await _s.write(key: '${which}_salt', value: salt);
    await _s.write(key: '${which}_hash', value: _hash(pin, salt));
  }

  static Future<bool> checkPin(String which, String pin) async {
    final salt = await _s.read(key: '${which}_salt');
    final h = await _s.read(key: '${which}_hash');
    if (salt == null || h == null) return false;
    return _hash(pin, salt) == h;
  }

  static Future<void> removePin(String which) async {
    await _s.delete(key: '${which}_salt');
    await _s.delete(key: '${which}_hash');
  }

  // ---- Fingerprint flag ----
  static Future<bool> get bioEnabled async => await _s.read(key: 'bio') == '1';
  static Future<void> setBio(bool v) => _s.write(key: 'bio', value: v ? '1' : '0');

  // ---- Keys and folders ----
  static Future<Uint8List> key(String vault) async {
    var k = await _s.read(key: 'key_$vault');
    if (k == null) {
      k = base64Encode(List.generate(32, (_) => _rng.nextInt(256)));
      await _s.write(key: 'key_$vault', value: k);
    }
    return base64Decode(k);
  }

  static Future<Directory> dir(String vault) async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/$vault');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory> _tmp() async {
    final base = await getTemporaryDirectory();
    final d = Directory('${base.path}/view');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<void> clearTemp() async {
    try {
      final base = await getTemporaryDirectory();
      final d = Directory('${base.path}/view');
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {}
  }

  // ---- Index (id -> original name) ----
  static Future<Map<String, String>> readIndex(Directory d) async {
    final f = File('${d.path}/index.json');
    if (!await f.exists()) return {};
    return Map<String, String>.from(jsonDecode(await f.readAsString()));
  }

  static Future<void> _writeIndex(Directory d, Map<String, String> m) async {
    await File('${d.path}/index.json').writeAsString(jsonEncode(m));
  }

  // ---- Files ----
  static Future<void> addFile(String vault, String srcPath, String name) async {
    final d = await dir(vault);
    final k = await key(vault);
    final id = _rand(9).replaceAll(RegExp(r'[^A-Za-z0-9]'), 'x');
    final dest = '${d.path}/$id.enc';
    await Isolate.run(() => _encryptFile(srcPath, dest, k));
    final idx = await readIndex(d);
    idx[id] = name;
    await _writeIndex(d, idx);
  }

  static Future<String> decryptToTemp(String vault, String id, String name) async {
    final d = await dir(vault);
    final k = await key(vault);
    final t = await _tmp();
    final src = '${d.path}/$id.enc';
    final out = '${t.path}/$name';
    await Isolate.run(() => _decryptFile(src, out, k));
    return out;
  }

  static Future<void> deleteFile(String vault, String id) async {
    final d = await dir(vault);
    final f = File('${d.path}/$id.enc');
    if (await f.exists()) await f.delete();
    final idx = await readIndex(d);
    idx.remove(id);
    await _writeIndex(d, idx);
  }
}

void _encryptFile(String src, String dest, Uint8List key) {
  final bytes = File(src).readAsBytesSync();
  final iv = enc.IV.fromSecureRandom(12);
  final e = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
  final out = e.encryptBytes(bytes, iv: iv);
  final b = BytesBuilder()
    ..add(iv.bytes)
    ..add(out.bytes);
  File(dest).writeAsBytesSync(b.toBytes());
}

void _decryptFile(String src, String dest, Uint8List key) {
  final all = File(src).readAsBytesSync();
  final iv = enc.IV(Uint8List.fromList(all.sublist(0, 12)));
  final e = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
  final plain = e.decryptBytes(enc.Encrypted(Uint8List.fromList(all.sublist(12))), iv: iv);
  File(dest).writeAsBytesSync(plain);
}
