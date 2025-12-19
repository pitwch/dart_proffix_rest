import 'dart:convert';

class ProffixError {
  final String message;
  final String type;
  final List<ProffixErrorField>? fields;

  const ProffixError({
    this.message = '',
    this.type = '',
    this.fields,
  });

  @override
  String toString() =>
      'ProffixError(message: $message, type: $type, fields: $fields)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProffixError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          type == other.type &&
          _listEquals(fields, other.fields);

  @override
  int get hashCode => Object.hash(message, type, fields);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ProffixErrorField {
  final String name;
  final String message;
  final String reason;

  const ProffixErrorField({
    this.name = '',
    this.message = '',
    this.reason = '',
  });

  @override
  String toString() =>
      'ProffixErrorField(name: $name, message: $message, reason: $reason)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProffixErrorField &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          message == other.message &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(name, message, reason);
}

class ProffixException implements Exception {
  final dynamic body;
  final int? statusCode;

  const ProffixException({this.body, this.statusCode});

  String get _prefix =>
      statusCode != null ? 'ProffixException[$statusCode]' : 'ProffixException';

  Map<String, dynamic>? get _parsedBody {
    final raw = body?.toString();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    final raw = body?.toString();
    if (raw == null || raw.isEmpty) return _prefix;

    final json = _parsedBody;
    if (json == null) return raw;

    final msgDyn = json['Message'];
    final message = (msgDyn is String && msgDyn.isNotEmpty) ? msgDyn : _prefix;

    final fieldsDyn = json['Fields'];
    if (fieldsDyn is List) {
      final names = fieldsDyn
          .whereType<Map>()
          .map((f) => f['Name'])
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        return '$message (${names.join(', ')})';
      }
    }
    return message;
  }

  ProffixError toPxError() {
    final raw = body?.toString();
    if (raw == null || raw.isEmpty) {
      return const ProffixError(message: 'ProffixException');
    }

    final json = _parsedBody;
    if (json == null) return ProffixError(message: raw);

    final msgDyn = json['Message'];
    final typeDyn = json['Type'];
    final fieldsDyn = json['Fields'];

    List<ProffixErrorField>? fields;
    if (fieldsDyn is List) {
      final parsed = fieldsDyn.whereType<Map>().map((f) {
        return ProffixErrorField(
          name: (f['Name'] ?? '').toString(),
          reason: (f['Reason'] ?? '').toString(),
          message: (f['Message'] ?? '').toString(),
        );
      }).toList();
      if (parsed.isNotEmpty) fields = parsed;
    }

    return ProffixError(
      message: msgDyn is String ? msgDyn : '',
      type: typeDyn is String ? typeDyn : '',
      fields: fields,
    );
  }
}
