class ProffixException implements Exception {
  final String? message;
  final int? code;
  final dynamic response;

  ProffixException([this.message = "", this.code, this.response]);

  @override
  String toString() {
    if (message == null) return "ProffixException";
    return "ProffixException: $message (${code ?? 0})";
  }
}
