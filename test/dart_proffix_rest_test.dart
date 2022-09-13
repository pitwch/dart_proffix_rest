import 'dart:convert';
import "package:crypto/crypto.dart";
import 'package:dart_proffix_rest/dart_proffix_rest.dart';
import 'package:test/test.dart';

// Generating code coverage:
// 1. `dart pub global activate coverage`
// 2. `dart test --coverage="coverage"`
// 3. `dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --packages=.packages --report-on=lib`

// Upload code coverage to codecov.io
// `./codecov -t ${CODECOV_TOKEN}`

void main() {
  test('Check Login', () async {
    var bytesToHash = utf8.encode('gast123');
    var sha256Digest = sha256.convert(bytesToHash);
    var tempClient = ProffixClient(
        database: 'DEMODB',
        restURL: 'https://remote.proffix.net:11011',
        username: 'Gast',
        password: sha256Digest.toString());

    var request =
        await tempClient.get(endpoint: "ADR/Adresse", params: {"Limit": "1"});
    expect(request.statusCode, 200);

    var lgout = await tempClient.logout();
    expect(lgout.statusCode, 204);

    tempClient.close();
  });
}
