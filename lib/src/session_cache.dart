import 'dart:convert';
import 'dart:io';

/// Simple file-backed cache for storing a single PxSessionId string.
///
/// It chooses a per-user cache directory:
/// - On Windows: %APPDATA%/dart_proffix_rest
/// - Else: system temp directory + /dart_proffix_rest
///
/// The filename is derived from [username], [database], and [restURL] to avoid collisions
/// when multiple clients are used.
class FileSessionCache {
  final String username;
  final String database;
  final String restURL;

  FileSessionCache({
    required this.username,
    required this.database,
    required this.restURL,
  });

  static FileSessionCache withDefaults(
      String username, String database, String restURL) {
    return FileSessionCache(
        username: username, database: database, restURL: restURL);
  }

  Future<String?> load() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.isEmpty) return null;
      return content;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String sessionId) async {
    try {
      final file = await _cacheFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(sessionId, flush: true);
    } catch (_) {
      // ignore errors
    }
  }

  Future<void> clear() async {
    try {
      final file = await _cacheFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // ignore errors
    }
  }

  Future<File> _cacheFile() async {
    final dir = await _cacheDir();
    final safeName =
        base64Url.encode(utf8.encode('$username|$database|$restURL'));
    return File('${dir.path}${Platform.pathSeparator}$safeName.session');
  }

  Future<Directory> _cacheDir() async {
    Directory base;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        base = Directory('$appData${Platform.pathSeparator}dart_proffix_rest');
      } else {
        base = Directory.systemTemp.createTempSync('dart_proffix_rest');
      }
    } else {
      base = Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}dart_proffix_rest');
    }
    return base;
  }
}
