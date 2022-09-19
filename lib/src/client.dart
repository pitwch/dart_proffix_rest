import 'dart:convert';

import 'package:async/async.dart';
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
    String? pxSessionID,
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

    if (pxSessionID == null) {
      _pxSessionID = "";
    } else {
      _pxSessionID = pxSessionID;
    }

    if (_options.volumeLicence) {
      modules = ["VOL"];
    }
  }

  /// HTTP Client
  late Client _httpClient;

  /// Proffix Rest Options
  late ProffixRestOptions _options;

  /// Modules / Licences Proffix
  late List<String>? modules;

  /// Username in Proffix
  final String username;

  /// Password in Proffix (SHA256 - Hash; use Helper Method convertSHA256 to convert)
  final String password;

  /// Database Proffix
  final String database;

  /// Rest API Url in format https://myserver.ch:12233
  final String restURL;

  /// PxSessionId
  String _pxSessionID = "";

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
      var loginResponse = await _httpClient.post(loginUri,
          body: loginBody,
          headers: {
            'content-type': 'application/json'
          }).timeout(Duration(seconds: _options.timeout));

      switch (loginResponse.statusCode) {
        case 201:
          _pxSessionID = loginResponse.headers["pxsessionid"]!;
          return loginResponse;
        default:
          throw ProffixException(
              body: loginResponse.body, statusCode: loginResponse.statusCode);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Result.error(e.toString());
    }
  }

  /// Do logout on Proffix REST-API and deletes PxSessionId
  Future<Response> logout({
    httpClient,
  }) async {
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': _pxSessionID,
    });
    try {
      final logoutUri = buildUriPx(restURL,
          [_options.apiPrefix, _options.version, _options.loginEndpoint]);

      var logoutTask = await _httpClient
          .delete(logoutUri, headers: headers)
          .timeout(Duration(seconds: _options.timeout));

      // Clear PxSessionId
      _pxSessionID = "";

      /// It's important to close each client when it's done being used; failing to do so can cause the Dart process to hang.
      _httpClient.close();

      return logoutTask;
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// Utility method to make http get call
  @override
  Future<Response> get({
    String endpoint = '',
    Map<String, dynamic>? params,
  }) async {
    // return await call('get', path: path, headers: headers, params: params);
    String pxsessionid = await getPxSessionId();
    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxsessionid,
    });

    try {
      final getUri = _getUriUrl(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
              .toString(),
          params!);

      var resp = await _httpClient
          .get(getUri, headers: headers)
          .timeout(Duration(seconds: _options.timeout));

      switch (resp.statusCode) {
        case 200:
          // Update PxSessionId
          setPxSessionId(resp.headers["pxsessionid"]);
          return resp;
        default:
          throw Result.error(
              ProffixException(body: resp.body, statusCode: resp.statusCode));
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// Utility method to make http post call
  @override
  Future<Response> post({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();

    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxsessionid,
    });

    try {
      var resp = await _httpClient
          .post(
              buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, endpoint]),
              headers: headers,
              body: json.encode(data))
          .timeout(Duration(seconds: _options.timeout));

      // Update PxSessionId
      setPxSessionId(resp.headers["pxsessionid"]);
      return resp;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// Utility method to make http patch call
  @override
  Future<Response> patch({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();

    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxsessionid,
    });

    try {
      var resp = await _httpClient
          .patch(
              buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, endpoint]),
              headers: headers,
              body: jsonEncode(data))
          .timeout(Duration(seconds: _options.timeout));

      // Update PxSessionId
      setPxSessionId(resp.headers["pxsessionid"]);

      return resp;
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// Utility method to make http put call
  @override
  Future<Response> put({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();

    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxsessionid,
    });

    try {
      var resp = await _httpClient
          .put(
              buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, endpoint]),
              headers: headers,
              body: json.encode(data))
          .timeout(Duration(seconds: _options.timeout));

      // Update PxSessionId
      setPxSessionId(resp.headers["pxsessionid"]);

      return resp;
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// Utility method to make http delete call
  @override
  Future<Response> delete({String endpoint = ''}) async {
    String pxsessionid = await getPxSessionId();

    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxsessionid,
    });

    try {
      var resp = await _httpClient
          .delete(
              buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, endpoint]),
              headers: headers)
          .timeout(Duration(seconds: _options.timeout));

      // Update PxSessionId
      setPxSessionId(resp.headers["pxsessionid"]);
      return resp;
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// Utility method to directly get a list
  @override
  Future<Response> getList({
    int listeNr = 0,
    Map<String, dynamic>? data,
  }) async {
    // return await call('get', path: path, headers: headers, params: params);
    String pxsessionid = await getPxSessionId();

    Map<String, String> headers = {};
    headers.addAll({
      'content-type': 'application/json',
      'PxSessionId': pxsessionid,
    });

    try {
      data ??= {};
      var listDownload =
          await post(endpoint: "PRO/Liste/$listeNr/generieren", data: data);
      String? downloadLocation = listDownload.headers["location"];
      setPxSessionId(listDownload.headers["pxsessionid"]);
      Map<String, String> headersDownload = {};
      headersDownload.addAll({
        'PxSessionId': pxsessionid,
      });
      Uri downloadURI = Uri.parse(downloadLocation!);
      return await _httpClient
          .get(downloadURI, headers: headersDownload)
          .timeout(Duration(seconds: _options.timeout));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw ProffixException(body: e.toString());
    }
  }

  /// This method was taken from https://github.com/Ephenodrom/Dart-Basic-Utils/blob/master/lib/src/HttpUtils.dart#L279
  static Uri _getUriUrl(String url, Map<String, dynamic> queryParameters) {
    if (queryParameters.isEmpty) {
      return Uri.parse(url);
    }
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: queryParameters);
  }

  /// Manually sets the PxSessionId
  void setPxSessionId(String? pxsessionid) {
    print(pxsessionid);
    _pxSessionID = pxsessionid!;
  }

  /// Returns the used PxSessionId
  Future<String> getPxSessionId() async {
    if (_pxSessionID == "") {
      var lgn = await login(
          username: username,
          password: password,
          restURL: restURL,
          database: database,
          options: _options,
          modules: modules);

      if (lgn.statusCode != 201) {
        throw ProffixException(body: lgn.body, statusCode: lgn.statusCode);
      }
      String pxsessionid = lgn.headers["pxsessionid"].toString();

      setPxSessionId(pxsessionid);
      return pxsessionid;
    }
    return _pxSessionID;
  }
}
