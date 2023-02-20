import 'dart:convert';
import 'package:dart_proffix_rest/dart_proffix_rest.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
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

    postReq.fold((l) => null, (r) => expect(r.statusCode, 201));

    // Get LocationID

//Other way to 'extract' the data
    if (postReq.isRight()) {
      // ignore: cast_from_null_always_fails
      final Headers headers =
          postReq.getOrElse(() => throw UnimplementedError()).headers;
      tmpAdressNr = ProffixHelpers().convertLocationId(headers);
    }

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
    getReq.fold(
        (l) => null,
        (r) => {
              expect(r.statusCode, 200),
              expect(tmpAdressNr, jsonDecode(r.data.toString())[0]["AdressNr"]),
              expect(tmpAdressNr > 0, true),
              expect(ProffixHelpers().getFilteredCount(r.headers) > 0, true)
            });
  });

/*   test('Get Address Repeated Fast', () async {
    var i = 0;
    while (i < 20) {
      i++;
      // Get Request Test with Filter and Limit Parameters
      var getReq = await validClient.get(endpoint: "ADR/Adresse", params: {
        "Filter": "Name=='APITest'",
        "Fields": "AdressNr,Name,Vorname,Ort,PLZ",
        "Sort": "-AdressNr",
        "Limit": "4"
      });
      print("Run Loop $i");

      expect(getReq.statusCode, 200);
    }
  }); */

  test('Update Address (Patch)', () async {
    tmpAddress["AdressNr"] = tmpAdressNr;
    tmpAddress["Vorname"] = "Updated PATCH";
    // Patch Request Test
    var patchReq = await validClient.patch(
        endpoint: "ADR/Adresse/$tmpAdressNr", data: tmpAddress);

    patchReq.fold((l) => null, (r) => expect(r.statusCode, 204));
  });

  test('Update Address (Put)', () async {
    tmpAddress["AdressNr"] = tmpAdressNr;
    tmpAddress["Vorname"] = "Updated PUT";
    // Put Request Test
    var putReq = await validClient.put(
        endpoint: "ADR/Adresse/$tmpAdressNr", data: tmpAddress);
    putReq.fold((l) => null, (r) => expect(r.statusCode, 204));
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
    getReq.fold((l) => null, (r) => expect(r.statusCode, 204));
  });

  test('Get List', () async {
    // Search a list and get ListeNr
    var listSearch = await validClient.get(
        endpoint: "PRO/Liste",
        params: {"Filter": "name@='IMP_Protokoll.repx'", "Fields": "ListeNr"});

    listSearch.fold(
        (l) => null,
        (r) => {
              expect(r.statusCode, 200),
              validClient.getList(
                  listeNr: jsonDecode(r.data)[0]["ListeNr"], data: {}).then(
                (value) => value.fold(
                    (l) => null,
                    (r) => {
                          expect(r.headers["content-type"].toString(),
                              "application/pdf"),
                          expect(
                              int.parse(
                                      r.headers["content-length"].toString()) >
                                  0,
                              true)
                        }),
              )
            });
  });

  test('Check same Session (toString)', () async {
    var pxsessionidend = validClient.getPxSessionId().toString();
    // SessionId on End should be same as on start
    expect(tmpPxSessionId, pxsessionidend);
  });

  test('Check check login Endpoint', () async {
    var checkReq = await validClient.check();
    // SessionId on End should be same as on start
    checkReq.fold((l) => expect(l.statusCode, 200), (r) => null);
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
  test('Failed Login (Wrong Password)', () async {
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

  test('Failed Login (Wrong URL)', () async {
    var invalidClient2 = ProffixClient(
        database: envVars['PX_DB'].toString(),
        restURL: "https://sdfhdfhsdfsfe.ch:12323",
        username: envVars['PX_USER'].toString(),
        password: ProffixHelpers().convertSHA256("nonvalidlogin"),
        modules: ["VOL"],
        options: ProffixRestOptions(volumeLicence: true));

    // Check if ProffixException is thrown
    expect(() => invalidClient2.get(endpoint: "ADR/Adresse"),
        throwsA(isA<ProffixException>()));
  });
}
