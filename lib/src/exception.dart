import 'dart:convert';

class ProffixError {
  String message;
  String type;
  List<ProffixErrorField>? fields;
  ProffixError({this.message = "", this.type = "", this.fields});
}

class ProffixErrorField {
  String reason;
  String message;
  String name;
  ProffixErrorField({this.message = "", this.name = "", this.reason = ""});
}

class ProffixException implements Exception {
  dynamic body;
  int? statusCode;
  ProffixException({this.body, this.statusCode});

  @override
  String toString() {
    final prefix = statusCode != null
        ? "ProffixException[$statusCode]"
        : "ProffixException";
    final raw = body?.toString();
    if (raw == null || raw.isEmpty) {
      return prefix;
    }
    try {
      final dynamic jsonBody = jsonDecode(raw);
      final dynamic msgDyn =
          (jsonBody is Map<String, dynamic>) ? jsonBody["Message"] : null;
      final String message =
          (msgDyn is String && msgDyn.isNotEmpty) ? msgDyn : prefix;
      final dynamic fieldsDyn =
          (jsonBody is Map<String, dynamic>) ? jsonBody["Fields"] : null;
      if (fieldsDyn is Iterable) {
        final names = <String>[];
        for (final f in fieldsDyn) {
          if (f is Map && f["Name"] != null) {
            names.add(f["Name"].toString());
          }
        }
        if (names.isNotEmpty) {
          return "$message (${names.join(",")})";
        }
      }
      return message;
    } catch (_) {
      return raw;
    }
  }

  ProffixError toPxError() {
    final raw = body?.toString();
    if (raw == null || raw.isEmpty) {
      return ProffixError(message: "ProffixException");
    }
    try {
      final dynamic jsonBody = jsonDecode(raw);
      final pxerr = ProffixError();
      if (jsonBody is Map<String, dynamic>) {
        final msgDyn = jsonBody["Message"];
        final typeDyn = jsonBody["Type"];
        pxerr.message = (msgDyn is String) ? msgDyn : "";
        pxerr.type = (typeDyn is String) ? typeDyn : "";

        final fieldsDyn = jsonBody["Fields"];
        if (fieldsDyn is Iterable) {
          final fieldArray = <ProffixErrorField>[];
          for (final f in fieldsDyn) {
            if (f is Map) {
              fieldArray.add(
                ProffixErrorField(
                  name: (f["Name"] ?? "").toString(),
                  reason: (f["Reason"] ?? "").toString(),
                  message: (f["Message"] ?? "").toString(),
                ),
              );
            }
          }
          if (fieldArray.isNotEmpty) {
            pxerr.fields = fieldArray;
          }
        }
      }
      return pxerr;
    } catch (_) {
      return ProffixError(message: raw);
    }
  }
}
