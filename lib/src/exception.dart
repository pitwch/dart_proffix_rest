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
  String? body;
  int? statusCode;
  ProffixException({this.body, this.statusCode});

  @override
  String toString() {
    if (body == null) {
      return "ProffixException";
    } else if (body == "") {
      return "ProffixException";
    } else {
      var jsonBody = jsonDecode(body.toString());
      var message = jsonBody["Message"];
      List<String> fieldArray = [];
      //var type = jsonBody["Type"];
      var fields = jsonBody["Fields"];
      if (fields != null) {
        for (var field in fields) {
          fieldArray.add(field["Name"].toString());
        }
        return message + " (" + fieldArray.join(",") + ")";
      }
      return message;
    }
  }

  ProffixError toPxError() {
    if (body == null) {
      return ProffixError(message: "ProffixException");
    } else if (body == "") {
      return ProffixError(message: "ProffixException");
    } else {
      var pxerr = ProffixError();
      var jsonBody = jsonDecode(body.toString());
      pxerr.message = jsonBody["Message"];
      pxerr.type = jsonBody["Type"];

      List<ProffixErrorField> fieldArray = [];
      var fields = jsonBody["Fields"];
      if (fields != null) {
        for (var field in fields) {
          fieldArray.add(ProffixErrorField(
              name: field["Name"],
              reason: field["Reason"],
              message: field["Message"]));
        }
        pxerr.fields = fieldArray;
        return pxerr;
      }
      return pxerr;
    }
  }
}
