import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ProffixHelpers {
  const ProffixHelpers();

  static final DateFormat _pxDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateTime _epoch = DateTime.utc(1970, 1, 1);

  /// Convert the header of response [header] to amount of results of response.
  static int getFilteredCount(Headers header) {
    final pxmetadata = header.value('pxmetadata');
    if (pxmetadata == null || pxmetadata.isEmpty) return 0;
    try {
      final decoded = jsonDecode(pxmetadata);
      final count = decoded['FilteredCount'];
      return count is num ? count.toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Extracts the last path segment from the Location header.
  static String? _extractLocationSegment(Headers header) {
    final location = header.value('location');
    if (location == null || location.isEmpty) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.last;
  }

  /// Convert the header of response [header] to primary key created / updated object.
  static int convertLocationId(Headers header) {
    final segment = _extractLocationSegment(header);
    return segment != null ? (int.tryParse(segment) ?? 0) : 0;
  }

  /// Convert the header of response [header] to primary key created / updated object.
  static String convertLocationIdString(Headers header) {
    return _extractLocationSegment(header) ?? '';
  }

  /// Convert the Proffix time string [pxtime] to DateTime object.
  static DateTime convertPxTimeToTime(String? pxtime) {
    if (pxtime == null || pxtime.trim().isEmpty) return _epoch;
    try {
      return _pxDateFormat.parse(pxtime);
    } catch (_) {
      return _epoch;
    }
  }

  /// Convert the DateTime object [date] to Proffix time string.
  static String convertTimeToPxTime(DateTime? date) {
    return date != null ? _pxDateFormat.format(date) : '0000-00-00 00:00:00';
  }

  /// Convert the plain text password [password] to SHA-256 hashed password.
  static String convertSHA256(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
