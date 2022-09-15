import 'dart:convert';
import "package:crypto/crypto.dart";
import 'package:dart_proffix_rest/dart_proffix_rest.dart';
import 'package:test/test.dart';
import 'dart:io' show Platform;

// Generating code coverage:
// 1. `dart pub global activate coverage`
// 2. `dart test --coverage="coverage"`
// 3. `dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --packages=.packages --report-on=lib`

// Upload code coverage to codecov.io
// `./codecov -t ${CODECOV_TOKEN}`

void main() {
  Map<String, String> envVars = Platform.environment;
  var bytesToHash = utf8.encode(
    envVars['PX_PASS'].toString(),
  );
  var sha256Digest = sha256.convert(bytesToHash);
  var tempClient = ProffixClient(
      database: 'DEMODBPX5',
      restURL: envVars['PX_URL'].toString(),
      username: envVars['PX_USER'].toString(),
      password: sha256Digest.toString(),
      modules: ["VOL"],
      options: null);

  Map<String, dynamic> tmpAddress = {
    "Name": "APITest",
    "Vorname": "Rest",
    "Ort": "Zürich",
    "PLZ": "8000",
    "Land": {"LandNr": "CH"},
  };

  int tmpAdressNr = 0;

  test('Create Address', () async {
    // Create Address
    var postReq =
        await tempClient.post(endpoint: "ADR/Adresse", data: tmpAddress);
    expect(postReq.statusCode, 201);

    // Get LocationID
    /*   var locationId = postReq.headers["location"];
    if (locationId != null) {
      var q = Uri.parse(locationId);
      print(q);
    } */
  });

  test('Get Address', () async {
    // Get Request Test with Filter and Limit Parameters
    var getReq = await tempClient.get(endpoint: "ADR/Adresse", params: {
      "Filter": "Name=='APITest'",
      "Fields": "AdressNr,Name,Vorname,Ort,PLZ"
    });
    expect(getReq.statusCode, 200);

    final parsedJson = jsonDecode(getReq.body);
    tmpAdressNr = parsedJson[0]["AdressNr"];
    expect(tmpAdressNr > 0, true);
  });

  test('Delete Address', () async {
    // Get Request Test with Filter and Limit Parameters

    var getReq = await tempClient.delete(
      endpoint: "ADR/Adresse/$tmpAdressNr",
    );
    expect(getReq.statusCode, 204);
  });

  test('Logout', () async {
    var lgout = await tempClient.logout();
    expect(lgout.statusCode, 204);

    tempClient.close();
  });
}
