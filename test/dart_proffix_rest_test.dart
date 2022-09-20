import 'dart:convert';
import 'package:dart_proffix_rest/dart_proffix_rest.dart';
import 'package:dart_proffix_rest/src/client_options.dart';
import 'package:dart_proffix_rest/src/helpers.dart';
import 'package:test/test.dart';

import 'package:dotenv/dotenv.dart';

// Generating code coverage:
// 1. `dart pub global activate coverage`
// 2. `dart test --coverage="coverage"`
// 3. `dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --packages=.packages --report-on=lib`

// Upload code coverage to codecov.io
// `./codecov -t ${CODECOV_TOKEN}`

void main() {
  var envVars = DotEnv(includePlatformEnvironment: true)..load();

  var validClient = ProffixClient(
      database: envVars['PX_DB'].toString(),
      restURL: envVars['PX_URL'].toString(),
      username: envVars['PX_USER'].toString(),
      password: ProffixHelpers().convertSHA256(envVars['PX_PASS'].toString()),
      modules: ["VOL"],
      options: ProffixRestOptions(volumeLicence: true));

  Map<String, dynamic> tmpAddress = {
    "Name": "APITest",
    "Vorname": "Rest",
    "Ort": "Zürich",
    "PLZ": "8000",
    "DebitorenSteuercode": null,
    "Land": {"LandNr": "CH"},
  };

  int tmpAdressNr = 0;
  String tmpPxSessionId = '';
  DateTime tmpDateTime = DateTime.now();
  test('Create Address', () async {
    // Create Address
    var postReq =
        await validClient.post(endpoint: "ADR/Adresse", data: tmpAddress);

    expect(postReq.statusCode, 201);

    // Get LocationID
    tmpAdressNr = ProffixHelpers().convertLocationId(postReq.headers);

    // Temporary save PxSessionId for Check
    tmpPxSessionId = validClient.getPxSessionId().toString();
  });

  test('Get Address', () async {
    // Get Request Test with Filter and Limit Parameters
    var getReq = await validClient.get(endpoint: "ADR/Adresse", params: {
      "Filter": "Name=='APITest'",
      "Fields": "AdressNr,Name,Vorname,Ort,PLZ",
      "Sort": "-AdressNr",
      "Limit": "4"
    });
    expect(getReq.statusCode, 200);

    final parsedJson = jsonDecode(getReq.body);

    expect(tmpAdressNr, parsedJson[0]["AdressNr"]);
    expect(tmpAdressNr > 0, true);

    int count = ProffixHelpers().getFilteredCount(getReq.headers);
    expect(count > 0, true);
  });

  test('Update Address (Patch)', () async {
    tmpAddress["AdressNr"] = tmpAdressNr;
    tmpAddress["Vorname"] = "Updated PATCH";
    // Patch Request Test
    var patchReq = await validClient.patch(
        endpoint: "ADR/Adresse/$tmpAdressNr", data: tmpAddress);

    expect(patchReq.statusCode, 204);
  });

  test('Update Address (Put)', () async {
    tmpAddress["AdressNr"] = tmpAdressNr;
    tmpAddress["Vorname"] = "Updated PUT";
    // Put Request Test
    var putReq = await validClient.put(
        endpoint: "ADR/Adresse/$tmpAdressNr", data: tmpAddress);

    expect(putReq.statusCode, 204);
  });

  /*  test('Fail Test (Get)', () async {
    // Put Request Test
    var putReq = await validClient.get(endpoint: "ADR/Adresse/212121");

    expect(putReq.statusCode, 404);
  }); */

  test('Delete Address', () async {
    // Get Request Test with Filter and Limit Parameters

    var getReq = await validClient.delete(
      endpoint: "ADR/Adresse/$tmpAdressNr",
    );
    expect(getReq.statusCode, 204);
  });

  test('Get List', () async {
    // Search a list and get ListeNr
    var listSearch = await validClient.get(
        endpoint: "PRO/Liste",
        params: {"Filter": "name@='IMP_Protokoll.repx'", "Fields": "ListeNr"});

    expect(listSearch.statusCode, 200);
    var listeFirst = jsonDecode(listSearch.body)[0];
    int listeNr = listeFirst["ListeNr"];

    // Request Liste as File
    var listReq = await validClient.getList(listeNr: listeNr, data: {});

    expect(listReq.statusCode, 200);

    // Check if filetype is PDF
    expect(listReq.headers["content-type"].toString(), "application/pdf");

    // Check if Content-Lenght (=filesize) greater than 0
    expect(int.parse(listReq.headers["content-length"].toString()) > 0, true);
  });

  test('Check same Session (toString)', () async {
    var pxsessionidend = validClient.getPxSessionId().toString();
    // SessionId on End should be same as on start
    expect(tmpPxSessionId, pxsessionidend);
  });

  /*  test('Test Error on Create (toPxError)', () async {
    Map<String, dynamic> failedAddress = {
      "Name": "ToFailAddress",
    };

    // Check if ProffixException is thrown

    expect(() => validClient.post(endpoint: "ADR/Adresse", data: failedAddress).c,
        ProffixException().toPxError());
  }); */

  test('Test Error on Create', () async {
    Map<String, dynamic> failedAddress = {
      "Name": "ToFailAddress",
    };

    // Check if ProffixException is thrown
    expect(() => validClient.post(endpoint: "ADR/Adresse", data: failedAddress),
        throwsA(isA<ProffixException>()));
  });
  test('Logout', () async {
    var lgout = await validClient.logout();
    expect(lgout.statusCode, 204);
  });

  test('Check convertPxTimeToTime', () async {
    var tmpPxTime = ProffixHelpers().convertTimeToPxTime(tmpDateTime);
    var tmpTm = ProffixHelpers().convertPxTimeToTime(tmpPxTime);
    expect(tmpTm.difference(tmpDateTime).inSeconds, 0);
  });
  test('Failed Login', () async {
    var invalidClient = ProffixClient(
        database: envVars['PX_DB'].toString(),
        restURL: envVars['PX_URL'].toString(),
        username: envVars['PX_USER'].toString(),
        password: ProffixHelpers().convertSHA256("nonvalidlogin"),
        modules: ["VOL"],
        options: ProffixRestOptions(volumeLicence: true));

    // Check if ProffixException is thrown
    expect(() => invalidClient.get(endpoint: "ADR/Adresse"),
        throwsA(isA<ProffixException>()));
  });
}
