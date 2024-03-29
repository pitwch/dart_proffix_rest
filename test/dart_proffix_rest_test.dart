import 'dart:io';
import 'dart:typed_data';

import 'package:dart_proffix_rest/dart_proffix_rest.dart';
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
      enableLogger: false,
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
  String? tmpDateiNr;

  group('API Tests', () {
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

      final parsedJson = getReq.data;

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
      var listSearch = await validClient.get(endpoint: "PRO/Liste", params: {
        "Filter": "name@='IMP_Protokoll.repx'",
        "Fields": "ListeNr"
      });

      expect(listSearch.statusCode, 200);
      var listeFirst = (listSearch.data)[0];
      int listeNr = listeFirst["ListeNr"];

      // Request Liste as File
      var listReq = await validClient.getList(listeNr: listeNr, data: {});

      expect(listReq.statusCode, 200);

      // Check if filetype is PDF
      expect(
          listReq.headers.value("content-type").toString(), "application/pdf");

      // Check if Content-Lenght (=filesize) greater than 0
      expect(int.parse(listReq.headers.value("content-length").toString()) > 0,
          true);
    });

    test('Check same Session (toString)', () async {
      var pxsessionidend = validClient.getPxSessionId().toString();
      // SessionId on End should be same as on start
      expect(tmpPxSessionId, pxsessionidend);
    });

    test('Check check login Endpoint', () async {
      var checkReq = await validClient.check();
      // SessionId on End should be same as on start
      expect(checkReq.statusCode, 200);
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
      expect(
          () => validClient.post(endpoint: "ADR/Adresse", data: failedAddress),
          throwsA(isA<ProffixException>()));

      // Check if ProffixException toPxError works
      expect(
          () => validClient.post(endpoint: "ADR/Adresse", data: failedAddress),
          throwsA(predicate((e) =>
              e is ProffixException && e.toPxError().fields!.isNotEmpty)));
    });

    test('Upload File (Post)', () async {
      // Read file
      final File file = File("_assets/big_image.png");

      var bytes = file.readAsBytesSync();
      var dataUpload = Uint8List.fromList(bytes);
      // Put Request Test
      var uploadReq =
          await validClient.uploadFile(data: dataUpload, fileName: "testBild");

      // Set tmpDateiNr for other tests
      tmpDateiNr = uploadReq;

      expect(uploadReq != "", true);
    });

    test('Download File (Get)', () async {
      // Read file

      var downloadReq =
          await validClient.downloadFile(dateiNr: tmpDateiNr.toString());
      expect(downloadReq.statusCode, 200);
    });
  });

  group('Extended tests', () {
    test('Check convertPxTimeToTime', () async {
      var tmpPxTime = ProffixHelpers().convertTimeToPxTime(tmpDateTime);
      var tmpTm = ProffixHelpers().convertPxTimeToTime(tmpPxTime);
      expect(tmpTm.difference(tmpDateTime).inSeconds, 0);

      // Check null
      var nullTime = ProffixHelpers().convertPxTimeToTime(null);
      expect(nullTime.hour, 0);

      var nullPxTime = ProffixHelpers().convertTimeToPxTime(null);
      expect(nullPxTime, "0000-00-00 00:00:00");
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

      // Check if check works
      expect(() => invalidClient.check(), throwsA(isA<ProffixException>()));
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
    test('Test BaseProffixClient', () async {});
  });

  test('Logout', () async {
    var lgout = await validClient.logout();
    expect(lgout.statusCode, 204);
  });
}
