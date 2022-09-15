import 'dart:convert';

import 'package:http/http.dart';

import 'client_base.dart';
import 'client_options.dart';
import '../dart_proffix_rest.dart';

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
    this.modules,
    ProffixRestOptions? options,
    Client? httpClient,
  }) {
    if (httpClient == null) {
      _httpClient = Client();
    } else {
      _httpClient = httpClient;
    }
    if (options == null) {
      _options = ProffixRestOptions();
      _options.apiPrefix = "pxapi";
      _options.loginEndpoint = "PRO/Login";
      _options.volumeLicence = false;
    } else {
      _options = options;
    }
  }

  /// HTTP Client
  late Client _httpClient;

  /// Proffix Rest Options
  late ProffixRestOptions _options;

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
  String pxSessionID = "";

  // Utilities
  Uri buildUriPx(String base, List<String> frags) {
    Uri q = Uri.parse(base);
    q.removeFragment;
    List<String> cleanedFrags = [];
    for (String frag in frags) {
      List<String> subFrags = frag.split("/");
      for (String subFrag in subFrags) {
        cleanedFrags.add(subFrag);
      }
    }
    return Uri(
        scheme: q.scheme,
        port: q.port,
        host: q.host,
        pathSegments: cleanedFrags);
  }

  /// Utility method to Login
  Future<Response> login({
    required username,
    required password,
    required restURL,
    required database,
    required options,
    modules,
    httpClient,
  }) async {
    try {
      final loginUri = buildUriPx(
          restURL, [options.apiPrefix, options.version, options.loginEndpoint]);

      final loginBody = jsonEncode({
        "Benutzer": username,
        "Passwort": password,
        "Datenbank": {"Name": database},
        "Module": modules
      });
      return await _httpClient.post(loginUri,
          body: loginBody, headers: {'content-type': 'application/json'});
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  /// Utility method to Logout
  Future<Response> logout({
    httpClient,
  }) async {
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });
    try {
      final logoutUri = buildUriPx(restURL,
          [_options.apiPrefix, _options.version, _options.loginEndpoint]);
      return await _httpClient.delete(logoutUri, headers: headers);
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  /// Utility method to make http get call
  @override
  Future<Response> get({
    String endpoint = '',
    Map<String, dynamic>? params,
  }) async {
    // return await call('get', path: path, headers: headers, params: params);
    var loginObj = await login(
        options: _options,
        username: username,
        password: password,
        restURL: restURL,
        database: database,
        modules: modules);

    pxSessionID = loginObj.headers["pxsessionid"]!;
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      final getUri = _getUriUrl(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
              .toString(),
          params!);

      return await _httpClient.get(getUri, headers: headers);
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
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    var loginObj = await login(
        options: _options,
        username: username,
        password: password,
        restURL: restURL,
        database: database,
        modules: modules);

    pxSessionID = loginObj.headers["pxsessionid"]!;
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      return await _httpClient.post(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint]),
          headers: headers,
          body: json.encode(data));
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  /// Utility method to make http patch call
  @override
  Future<Response> patch({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    var loginObj = await login(
        options: _options,
        username: username,
        password: password,
        restURL: restURL,
        database: database,
        modules: modules);

    pxSessionID = loginObj.headers["pxsessionid"]!;
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      return await _httpClient.patch(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint]),
          headers: headers,
          body: jsonEncode(data));
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  /// Utility method to make http put call
  @override
  Future<Response> put({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    var loginObj = await login(
        options: _options,
        username: username,
        password: password,
        restURL: restURL,
        database: database,
        modules: modules);

    pxSessionID = loginObj.headers["pxsessionid"]!;
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      return await _httpClient.put(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint]),
          headers: headers,
          body: json.encode(data));
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  /// Utility method to make http delete call
  @override
  Future<Response> delete({String endpoint = ''}) async {
    // return await call('post', path: path, headers: headers, data: data);
    var loginObj = await login(
        options: _options,
        username: username,
        password: password,
        restURL: restURL,
        database: database,
        modules: modules);

    pxSessionID = loginObj.headers["pxsessionid"]!;
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxSessionID,
    });

    try {
      return await _httpClient.delete(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint]),
          headers: headers);
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(e.toString());
    }
  }

  // This method was taken from https://github.com/Ephenodrom/Dart-Basic-Utils/blob/master/lib/src/HttpUtils.dart#L279
  static Uri _getUriUrl(String url, Map<String, dynamic> queryParameters) {
    if (queryParameters.isEmpty) {
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
