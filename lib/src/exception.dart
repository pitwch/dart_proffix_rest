class ProffixException implements Exception {
  String? message;
  String? endpoint;
  String? type;
  int? status;
  List<ProffixExceptionField>? fields;
  ProffixException(
      [this.message = "", this.endpoint, this.type, this.status, this.fields]);

  factory ProffixException.fromJson(Map<String, dynamic> jsonData) {
    return ProffixException()
      ..message = jsonData['Message']
      ..endpoint = jsonData['Endpoint']
      ..type = jsonData['Type']
      ..status = jsonData['Status']
      ..fields = jsonData['Fields'];
  }
  @override
  String toString() {
    if (message == null) return "ProffixException";
    return "ProffixException: $message (${status ?? 0}: $fields)";
  }
}

class ProffixExceptionField {
  final String? reason;
  final String? name;
  final String? message;
  ProffixExceptionField([this.reason = "", this.name, this.message]);
}
