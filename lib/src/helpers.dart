import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class ProffixHelpers {
  /// Convert the header of response [header] to amount of results of response.
  int getFilteredCount(Map<String, String> header) {
    String? pxmetadata = header["pxmetadata"];
    if (pxmetadata != "") {
      return jsonDecode(pxmetadata!)["FilteredCount"];
    } else {
      return 0;
    }
  }

  /// Convert the header of response [header] to primary key created / updated object.
  int convertLocationId(Map<String, String> header) {
    String? location = header["location"];
    if (location != "" && location != null) {
      String lastPath = Uri.parse(location).pathSegments.last;
      return int.parse(lastPath);
    } else {
      return 0;
    }
  }

  /// Convert the Proffix time string [pxtime] to DateTime object.
  DateTime convertPxTimeToTime(String pxtime) {
    DateFormat pxformat = DateFormat("yyyy-dd-MM HH:mm:ss");
    return pxformat.parse(pxtime);
  }

  /// Convert the DateTime object [date] Proffix times string.
  String convertTimeToPxTime(DateTime date) {
    final DateFormat pxformat = DateFormat("yyyy-dd-MM HH:mm:ss");
    return pxformat.format(date);
  }

  /// Convert the plain text password [password] to SHA-256 hashed password.
  String convertSHA256(String password) {
    var pwHash = utf8.encode(password);
    var hashedPw = sha256.convert(pwHash);
    return hashedPw.toString();
  }
}
