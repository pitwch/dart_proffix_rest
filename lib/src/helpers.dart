import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ProffixHelpers {
  /// Convert the header of response [header] to amount of results of response.
  int getFilteredCount(Headers header) {
    final String? pxmetadata = header.value("pxmetadata");
    if (pxmetadata == null || pxmetadata.isEmpty) {
      return 0;
    }
    try {
      final dynamic decoded = jsonDecode(pxmetadata);
      final dynamic count = decoded["FilteredCount"];
      if (count is num) {
        return count.toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Convert the header of response [header] to primary key created / updated object.
  int convertLocationId(Headers header) {
    final String? location = header.value("location");
    if (location == null || location.isEmpty) {
      return 0;
    }
    final uri = Uri.tryParse(location);
    if (uri == null || uri.pathSegments.isEmpty) {
      return 0;
    }
    final lastPath = uri.pathSegments.last;
    return int.tryParse(lastPath) ?? 0;
  }

  /// Convert the header of response [header] to primary key created / updated object.
  String convertLocationIdString(Headers header) {
    final String? location = header.value("location");
    if (location == null || location.isEmpty) {
      return "";
    }
    final uri = Uri.tryParse(location);
    if (uri == null || uri.pathSegments.isEmpty) {
      return "";
    }
    return uri.pathSegments.last;
  }

  /// Convert the Proffix time string [pxtime] to DateTime object.
  DateTime convertPxTimeToTime(String? pxtime) {
    if (pxtime == null || pxtime.trim().isEmpty) {
      // Fallback: epoch-like value
      return DateTime.utc(1970, 1, 1);
    }
    try {
      // PROFFIX examples use 'yyyy-MM-dd HH:mm:ss' (e.g., 2004-04-11 00:00:00)
      final DateFormat pxformat = DateFormat("yyyy-MM-dd HH:mm:ss");
      return pxformat.parse(pxtime);
    } catch (_) {
      return DateTime.utc(1970, 1, 1);
    }
  }

  /// Convert the DateTime object [date] Proffix times string.
  String convertTimeToPxTime(DateTime? date) {
    if (date == null) {
      return "0000-00-00 00:00:00";
    }
    final DateFormat pxformat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return pxformat.format(date);
  }

  /// Convert the plain text password [password] to SHA-256 hashed password.
  String convertSHA256(String password) {
    var pwHash = utf8.encode(password);
    var hashedPw = sha256.convert(pwHash);
    return hashedPw.toString();
  }
}
