<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

<!-- markdownlint-disable MD041 -->

[![pub package](https://img.shields.io/pub/v/dart_proffix_rest)](https://pub.dev/packages/dart_proffix_rest)
[![codecov](https://codecov.io/gh/pitwch/dart_proffix_rest/branch/main/graph/badge.svg?token=MDG6GG8RCE)](https://codecov.io/gh/pitwch/dart_proffix_rest)
[![License](https://img.shields.io/github/license/pitwch/dart_proffix_rest)](https://github.com/pitwch/dart_proffix_rest/blob/main/LICENSE)

# Dart Wrapper für PROFFIX REST-API

![alt text](https://raw.githubusercontent.com/pitwch/dart_proffix_rest/main/_assets/dart-proffix.png "Dart Wrapper PROFFIX REST API")

## Übersicht

- [Installation](#installation)
  - [Konfiguration](#konfiguration)
- [Optionen](#optionen)
  - [Methoden](#methoden)
  - [Spezielle Endpunkte](#spezielle-endpunkte)
- [Weitere Beispiele](#weitere-beispiele)

## Installation

```bash
dart pub add dart_proffix_rest
```

### Konfiguration

Die Konfiguration wird dem Client mitgegeben:

| Konfiguration | Beispiel                                | Type                 | Bemerkung                             |
|---------------|-----------------------------------------|----------------------|---------------------------------------|
| restURL       | <https://myserver.ch:12299>             | `string`             | URL der REST-API **ohne pxapi/v4/**   |
| database      | DEMO                                    | `string`             | Name der Datenbank                    |
| username      | USR                                     | `string`             | Names des Benutzers                   |
| password      | b62cce2fe18f7a156a9c...                 | `string`             | SHA256-Hash des Benutzerpasswortes    |
| modules       | ["ADR", "FIB"]                          | `List<String>?`      | Benötigte Module (mit Komma getrennt) |
| options       | ProffixRestOptions(volumeLicence: true) | `ProffixRestOptions` | Optionen (Details unter Optionen)     |

Beispiel:

```dart
import 'package:dart_proffix_rest/dart_proffix_rest.dart';


var pxClient = ProffixClient(
        database: 'DEMODBPX5',
        restURL: 'https://myserver.ch:12299',
        username: 'USR',
        password: 'b62cce2fe18f7a156a9c719c57bebf0478a3d50f0d7bd18d9e8a40be2e663017',
        modules: ["VOL"],
        options: null);;

    var request =
        await pxClient.get(endpoint: "ADR/Adresse", params: {"Limit": "1"});


```

### Optionen

Optionen sind **fakultativ** und werden in der Regel nicht benötigt:

| Option        | Beispiel                              | Bemerkung                                                      |
|---------------|---------------------------------------|----------------------------------------------------------------|
| key           | 112a5a90fe28b...242b10141254b4de59028 | API-Key als SHA256 - Hash (kann auch direkt mitgegeben werden) |
| version       | v3                                    | API-Version; Standard = v3                                     |
| loginEndpoint | /pxapi/                               | Prefix für die API; Standard = /pxapi/                         |
| LoginEndpoint | PRO/Login                             | Endpunkt für Login; Standard = PRO/Login                       |
| userAgent     | DartWrapper                           | User Agent; Standard = DartWrapper                             |
| timeout       | 30                                    | Timeout in Sekunden                                            |
| verifySSL     | true                                  | SSL prüfen                                                     |
| batchsize     | 200                                   | Batchgrösse für Batchrequests; Standard = 200                  |
| log           | true                                  | Aktiviert den Log für Debugging; Standard = false              |
| volumeLicence | false                                 | Nutzt PROFFIX Volumenlizenzierung                              |

#### Methoden

| Parameter  | Typ                     | Bemerkung                                                                                                |
|------------|-------------------------|----------------------------------------------------------------------------------------------------------|
| endpoint   | `string`                | Endpunkt der PROFFIX REST-API; z.B. ADR/Adresse,STU/Rapporte...                                          |
| data       | `string`                | Daten (werden automatisch in JSON konvertiert)                                                           |
| parameters | `Map<String, dynamic>?` | Parameter gemäss [PROFFIX REST API Docs](http://www.proffix.net/Portals/0/content/REST%20API/index.html) |

Folgende unterschiedlichen Methoden sind mit dem Wrapper möglich:

##### Get / Query

```dart

    var request =
        await pxClient.get(endpoint: "ADR/Adresse/1", params: {"Fields": "AdressNr"});

```

##### Put / Update

```dart

    var request =
        await pxClient.put(endpoint: "ADR/Adresse/1", {
  "Name":   "Muster GmbH",
  "Ort":    "Zürich",
  "Zürich": "8000",
 });

```

##### Patch / Update

```dart

 var request =
        await pxClient.patch(endpoint: "ADR/Adresse/1", {
  "Name":   "Muster GmbH",
  "Ort":    "Zürich",
  "Zürich": "8000",
 });

```

##### Post / Create

```dart

 var request =
        await pxClient.post(endpoint: "ADR/Adresse/1", {
  "Name":   "Muster GmbH",
  "Ort":    "Zürich",
  "Zürich": "8000",
 });
```

##### Delete / Delete

```dart
  var request =
        await pxClient.delete(endpoint: "ADR/Adresse/1");
```

#### Spezielle Endpunkte

##### Logout

Loggt den Client von der PROFFIX REST-API aus und gibt die Session / Lizenz damit wieder frei. Zusätzlich wird der Dart Client geschlossen.

**Hinweis:** Es wird automatisch die zuletzt verwendete PxSessionId für den Logout verwendet

```dart

 var lgout = await pxClient.logout();


```

Der Wrapper führt den **Logout auch automatisch bei Fehlern** durch damit keine Lizenz geblockt wird.

##### GET List

Gibt direkt die Liste der PROFFIX REST API aus (ohne Umwege)

```dart

var list = await pxClient.getList(listeNr: 1232,data: {});


```

**Hinweis:** Der Dateityp (zurzeit nur PDF) kann über den Header `File-Type` ermittelt werden\*

#### Hilfsfunktionen

##### convertPxTimeToTime

Konvertiert einen Zeitstempel der PROFFIX REST-API in time.Time

```dart

var tim = ProffixHelpers().convertPxTimeToTime('2004-04-11 00:00:00')

```

##### convertTimeToPxTime

Konvertiert einen time.Time in einen Zeitstempel der PROFFIX REST-API

```dart

// Create DateTime from now
var timeNow = DateTime tmpDateTime = DateTime.now();

// Convert to PxTime
var tm = ProffixHelpers().convertTimeToPxTime(timeNow);


```

##### convertLocationId

Extrahiert die ID aus dem Header Location der PROFFIX REST-API

```dart

// Example Create Address
  var postReq =
        await tempClient.post(endpoint: "ADR/Adresse", data: {
    "Name": "Test",
    "Vorname": "Rest",
    "Ort": "Zürich",
    "PLZ": "8000",
    "Land": {"LandNr": "CH"},
  });

  // Get LocationID from Header --> returns newly created AdressNr from posted Address
 createdAdressNr = ProffixHelpers().convertLocationId(postReq.headers);

```

##### getFiltererCount

Extrahiert die Anzahl Ergebnisse aus dem Header PxMetaData der PROFFIX REST-API

```dart

// Example Get Address with Filter PLZ == Münchwilen
    var getReq = await tempClient.get(endpoint: "ADR/Adresse", params: {
      "Filter": "PLZ=='Münchwilen'",
      "Fields": "AdressNr,Name,Vorname,Ort,PLZ"
    });

  // Get FilteredCount from Header --> returns the total amount of filtered Addresses
 countAddresses = ProffixHelpers().getFiltererCount(getReq.headers);

```

### Weitere Beispiele

Im Ordner [/examples](https://github.com/pitwch/dart_proffix_rest/tree/master/_examples) finden sich weitere,
auskommentierte Beispiele.

<!-- markdownlint-enable MD041 -->
