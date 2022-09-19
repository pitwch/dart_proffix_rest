import 'dart:convert';
import "package:crypto/crypto.dart";
import 'package:dart_proffix_rest/dart_proffix_rest.dart';
import 'package:dart_proffix_rest/src/client_options.dart';
import 'package:dart_proffix_rest/src/helpers.dart';

void main() async {
  // Passwort hashen
  var pwHash = utf8.encode(
    "gast123",
  );
  var sha256Digest = sha256.convert(pwHash);

  // Login  vorbereiten
  var pxClient = ProffixClient(
      database: 'DEMODBPX5',
      restURL: "https://remote.proffix.ch:10001",
      username: "Gast",
      password: sha256Digest.toString(),
      modules: ["VOL"],
      options: ProffixRestOptions(volumeLicence: true));

  // Beispiel - Map für eine Adresse
  Map<String, dynamic> tmpAddress = {
    "Name": "APITest",
    "Vorname": "Rest",
    "Ort": "Zürich",
    "PLZ": "8000",
    "Land": {"LandNr": "CH"},
  };

  // Adresse erstellen
  var createAddress =
      await pxClient.post(endpoint: "ADR/Adresse", data: tmpAddress);

  // AdresseNr der neu erstellen Adresse anzeigen
  int adressNr = ProffixHelpers().convertLocationId(createAddress.headers);
  print("${"Die neue Adresse wurde mit AdressNr $adressNr"} erstellt");
  // Alle Adressen, welche wie 'Muster' lauten abrufen
  var getAddress = await pxClient.get(endpoint: "ADR/Adresse", params: {
    "Filter": "Name@='Muster'",
    "Fields": "AdressNr,Name,Vorname,Ort,PLZ"
  });

  // Die Anzahl der Suchergebnisse aus dem Header ziehen
  int countResults = ProffixHelpers().getFilteredCount(getAddress.headers);
  print("${"Es wurden $countResults"} Adressen für 'Muster' gefunden");

  // Die gefundenden Adressen aus JSON dekodieren
  var allResults = jsonDecode(getAddress.body);

  // Das erste Ergebnis / die erste Adresse extrahieren
  var firstResult = allResults[0];

  // Das 'ErstelltAm' Datum in ein DateTime Objekt umwandeln
  var erstelltAm =
      ProffixHelpers().convertPxTimeToTime(firstResult["ErstelltAm"]);

  // Die Differenz zwischen dem 'ErstelltAm' Datum und heute berechnen
  var differenz = erstelltAm.difference(DateTime.now());
  var differenzInTagen = differenz.inDays;
  print("${"Die erste Adresse wurde vor $differenzInTagen"} Tagen erstellt");

  // Ausloggen und aufräumen
  await pxClient.logout();
}
