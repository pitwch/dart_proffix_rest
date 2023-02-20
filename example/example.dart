import 'dart:convert';
import "package:crypto/crypto.dart";
import 'package:dart_proffix_rest/dart_proffix_rest.dart';

void main() async {
  // Passwort hashen
  var pwHash = utf8.encode(
    "1234",
  );
  var sha256Digest = sha256.convert(pwHash);

  // Login  vorbereiten
  var pxClient = ProffixClient(
      database: 'DEMODB',
      restURL: "https://work.pitw.ch:1500",
      username: "TM3",
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
  int q;
  createAddress.fold(
      (l) => {
            q = ProffixHelpers().convertLocationId(l.headers),
            print("Die neue Adresse wurde mit AdressNr $q erstellt"
                // Alle Adressen, welche wie 'Muster' lauten abrufen
                )
          },
      (r) => {print(r)});
  // AdresseNr der neu erstellen Adresse anzeigen
}
