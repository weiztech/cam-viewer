import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/host.dart';

/// Persists the host list with encryption, using the best mechanism per platform:
///
///   macOS / Android → AES-256-CBC encrypted file in ApplicationSupportDirectory.
///                     Reliable on all devices, no Keystore/signing dependency.
///                     File is app-private and wiped on uninstall.
///
///   iOS             → flutter_secure_storage (Keychain, hardware-backed).
///                     Includes reinstall-detection to clear leftover data.
class HostStorage {
  HostStorage._();

  // 32 ASCII chars = 256-bit AES key.
  static final _aesKey = enc.Key.fromUtf8('CamViewer_AES256_StorageKey_2024');
  static final _encrypter = enc.Encrypter(enc.AES(_aesKey));

  // iOS only
  static const _secureStorage = FlutterSecureStorage();
  static const _secureKey = 'cam_viewer_hosts';

  // macOS + Android
  static const _dataFile = 'cam_viewer_hosts.dat';

  // iOS reinstall detection
  static const _flagFile = '.cam_viewer_installed';

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<List<Host>> load() async {
    try {
      if (!kIsWeb && (Platform.isMacOS || Platform.isAndroid)) {
        return await _loadFromFile();
      }
      if (!kIsWeb && Platform.isIOS) {
        await _clearKeychainIfReinstalled();
      }
      return await _loadFromSecureStorage();
    } catch (e, st) {
      debugPrint('[HostStorage] load error: $e\n$st');
      return [];
    }
  }

  static Future<void> save(List<Host> hosts) async {
    try {
      if (!kIsWeb && (Platform.isMacOS || Platform.isAndroid)) {
        await _saveToFile(hosts);
      } else {
        await _saveToSecureStorage(hosts);
      }
    } catch (e) {
      debugPrint('[HostStorage] save error: $e');
    }
  }

  // ── AES-256 encrypted file (macOS + Android) ──────────────────────────────

  static Future<List<Host>> _loadFromFile() async {
    final file = await _dataFilePath();
    if (!file.existsSync()) return [];

    // Stored format: "<base64 IV>:<base64 ciphertext>"
    final stored = await file.readAsString();
    final parts = stored.split(':');
    if (parts.length != 2) return [];

    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);
    final json = _encrypter.decrypt(encrypted, iv: iv);

    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Host.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _saveToFile(List<Host> hosts) async {
    final json = jsonEncode(hosts.map((h) => h.toJson()).toList());
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(json, iv: iv);
    final stored = '${iv.base64}:${encrypted.base64}';

    final file = await _dataFilePath();
    await file.writeAsString(stored);
  }

  static Future<File> _dataFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_dataFile');
  }

  // ── Keychain (iOS only) ───────────────────────────────────────────────────

  static Future<List<Host>> _loadFromSecureStorage() async {
    final raw = await _secureStorage.read(key: _secureKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Host.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _saveToSecureStorage(List<Host> hosts) async {
    final raw = jsonEncode(hosts.map((h) => h.toJson()).toList());
    await _secureStorage.write(key: _secureKey, value: raw);
  }

  // ── iOS reinstall detection ───────────────────────────────────────────────

  static Future<void> _clearKeychainIfReinstalled() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final flag = File('${dir.path}/$_flagFile');
      if (!flag.existsSync()) {
        await _secureStorage.deleteAll();
        await flag.create(recursive: true);
      }
    } catch (_) {}
  }
}
