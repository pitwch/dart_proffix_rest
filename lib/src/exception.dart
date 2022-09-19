import 'dart:convert';

class ProffixException implements Exception {
  String? body;
  int? statusCode;
  ProffixException({this.body, this.statusCode});

  @override
  String toString() {
    if (body == null) return "ProffixException";

    if (body == "") return "ProffixException";

    var jsonBody = jsonDecode(body!);
    var message = jsonBody["Message"];
    // var type = jsonBody["Type"];
    //  var fields = jsonBody["Fields"];

    return "$message";
  }
}
