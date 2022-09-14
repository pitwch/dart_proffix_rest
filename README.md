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

## Installation

```bash
dart pub add dart_proffix_rest
```

### Konfiguration

Die Konfiguration wird dem Client mitgegeben:

| Konfiguration | Beispiel                    | Type          | Bemerkung                             |
| ------------- | --------------------------- | ------------- | ------------------------------------- |
| restURL       | <https://myserver.ch:12299> | `string`      | URL der REST-API **ohne pxapi/v4/**   |
| database      | DEMO                        | `string`      | Name der Datenbank                    |
| username      | USR                         | `string`      | Names des Benutzers                   |
| password      | b62cce2fe18f7a156a9c...     | `string`      | SHA256-Hash des Benutzerpasswortes    |
| modules       | []string{"ADR", "FIB"}      | `[]string`    | Benötigte Module (mit Komma getrennt) |
| options       | &px.Options{Timeout: 30}    | `*px.Options` | Optionen (Details unter Optionen)     |

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

<!-- markdownlint-enable MD041 -->
