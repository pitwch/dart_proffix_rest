class ProffixException implements Exception {
  String? Message;
  String? Endpoint;
  String? Type;
  int? Status;
  List<ProffixExceptionField>? Fields;
  ProffixException(
      [this.Message = "", this.Endpoint, this.Type, this.Status, this.Fields]);

  factory ProffixException.fromJson(Map<String, dynamic> jsonData) {
    return ProffixException()
      ..Message = jsonData['Message']
      ..Endpoint = jsonData['Endpoint']
      ..Type = jsonData['Type']
      ..Status = jsonData['Status']
      ..Fields = jsonData['Fields'];
  }
  @override
  String toString() {
    if (Message == null) return "ProffixException";
    return "ProffixException: $Message (${Status ?? 0}: ${Fields ?? null})";
  }
}

class ProffixExceptionField {
  final String? Reason;
  final String? Name;
  final String? Message;
  ProffixExceptionField([this.Reason = "", this.Name, this.Message]);
}
