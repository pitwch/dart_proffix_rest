import 'dart:convert';

import 'package:http/http.dart';

import 'client_base.dart';
import 'client_options.dart';
import '../dart_proffix_api.dart';

class ProffixClient implements BaseProffixClient {
  /// Creates a new instance of [ProffixClient]
  ///
  /// `username` - Username in Proffix.
  ///
  /// `password` - Password in Proffix.
  ///
  /// `database` - Database in Proffix.
  ///
  /// `restURL` - Url of Proffix Rest API`
  ///
  /// `modules` - Modules of Proffix Rest API`
  ///
  /// `options` - (Optional) Options of Proffix Rest API`
  ///
  /// `dioClient` - An existing Dio Client, if needed. When left null, an internal client will be created
  ProffixClient({
    required this.username,
    required this.password,
    required this.restURL,
    required this.database,
    List<String>? this.modules,
    ProffixRestOptions? this.options,
    Client? httpClient,
  }) {
    if (httpClient == null) {
      _httpClient = Client();
    } else {
      _httpClient = httpClient;
    }
  }

  /// HTTP Client
  late Client _httpClient;

  /// Proffix Rest Options
  final ProffixRestOptions? options;

  /// Modules / Licences Proffix
  final List<String>? modules;

  /// Username Proffix
  final String username;

  /// Password Proffix
  final String password;

  /// Database Proffix
  final String database;

  /// REST API URL
  final String restURL;

  /// PxSessionId
  final String pxSessionID;

  // Utilities

  /// Utility method to make http get call
  @override
  Future<Response> get({
    String path = '',
    Map<String, String>? headers,
    Map<String, dynamic>? params,
  }) async {
    // return await call('get', path: path, headers: headers, params: params);
    headers ??= {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      final finalUri = _getUriUrl(restURL + path, params!);
      return await _httpClient.get(finalUri, headers: headers);
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  /// Utility method to make http post call
  @override
  Future<Response> post({
    String path = '',
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    headers ??= {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      return await _httpClient.post(_getUriUrl(restURL + path, params!),
          headers: headers, body: json.encode(data));
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  // This method was taken from https://github.com/Ephenodrom/Dart-Basic-Utils/blob/master/lib/src/HttpUtils.dart#L279
  static Uri _getUriUrl(String url, Map<String, dynamic> queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return Uri.parse(url);
    }
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: queryParameters);
  }

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to do so can cause the Dart process to hang.
  void close() {
    _httpClient.close();
  }
}
