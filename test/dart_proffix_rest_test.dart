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
  test('Check Login', () async {
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

    var request =
        await tempClient.get(endpoint: "ADR/Adresse", params: {"Limit": "1"});
    expect(request.statusCode, 200);

    final parsedJson = jsonDecode(request.body);
    expect(parsedJson[0]["AdressNr"] > 0, true);

    var lgout = await tempClient.logout();
    expect(lgout.statusCode, 204);

    tempClient.close();
  });
}
