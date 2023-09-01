import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:dart_proffix_rest/dart_proffix_rest.dart';
import 'package:dart_proffix_rest/src/client_base.dart';
import 'package:dio/dio.dart';

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
    bool? enableLogger,
    Dio? dioClient,
  }) {
    if (dioClient == null) {
      _dioClient = Dio();
    } else {
      _dioClient = dioClient;
    }
    if (options == null) {
      ProffixRestOptions pxoptions = ProffixRestOptions(
          apiPrefix: "pxapi", loginEndpoint: "PRO/Login", volumeLicence: false);
      _options = pxoptions;
    } else {
      _options = options;
    }

    // _dioClient.options.headers["user-agent"] = _options.userAgent;

    if (pxSessionID == null) {
      _pxSessionID = "";
    } else {
      _pxSessionID = pxSessionID;
    }

    if (_options.volumeLicence) {
      modules = ["VOL"];
    }
  }

  /// Dio HTTP Client
  late Dio _dioClient;

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
  String buildUriPx(String base, List<String>? frags) {
    Uri q = Uri.parse(base);
    q.removeFragment;
    List<String> cleanedFrags = [];
    if (frags != null) {
      for (String frag in frags) {
        List<String> subFrags = frag.split("/");
        for (String subFrag in subFrags) {
          cleanedFrags.add(subFrag);
        }
      }
    }
    return Uri(
            scheme: q.scheme,
            port: q.port,
            host: q.host,
            pathSegments: cleanedFrags)
        .toString();
  }

  /// Utility method to Login
  Future<Response> login({
    required username,
    required password,
    required restURL,
    required database,
    required options,
    modules,
    dioClient,
  }) async {
    try {
      final loginUri = buildUriPx(
          restURL, [options.apiPrefix, options.version, options.loginEndpoint]);

      final loginBody = {
        "Benutzer": username,
        "Passwort": password,
        "Datenbank": {"Name": database},
        "Module": modules
      };

      _dioClient.options.contentType = Headers.jsonContentType;
      _dioClient.options.responseType = ResponseType.json;

      var loginResponse = await _dioClient
          .post(
            loginUri,
            data: loginBody,
          )
          .timeout(Duration(seconds: _options.timeout));
      switch (loginResponse.statusCode) {
        case 201:
          _pxSessionID = loginResponse.headers.value("pxsessionid")!;
          setPxSessionId(_pxSessionID);

          return loginResponse;
        default:
          throw ProffixException(
              body: jsonEncode(loginResponse.data),
              statusCode: loginResponse.statusCode);
      }
    } on DioException catch (e) {
      {
        /// Handle TimeoutException
        if (e is TimeoutException) {
          throw ProffixException(
              body: "Proffix Rest-API kann nicht erreicht werden (Timeout)",
              statusCode: 408);

          /// Handle other connection errors
        } else if (DioExceptionType.connectionError == e.type ||
            DioExceptionType.unknown == e.type) {
          throw ProffixException(
              body:
                  "Proffix Rest-API kann nicht erreicht werden (Verbindungsproblem)",
              statusCode: 0);

          /// Handle errors with response
        } else if (e.response != null) {
          throw ProffixException(
              body: e.response, statusCode: e.response?.statusCode ?? 0);
        } else {
          /// Handle everything else
          throw ProffixException(body: e.toString(), statusCode: 0);
        }
      }
    }
  }

  /// Do logout on Proffix REST-API and deletes PxSessionId
  Future<Response> logout({
    dioClient,
  }) async {
    _dioClient.options.headers['content-type'] = 'application/json';
    _dioClient.options.headers['PxSessionId'] = _pxSessionID;

    try {
      final logoutUri = buildUriPx(restURL,
          [_options.apiPrefix, _options.version, _options.loginEndpoint]);

      var logoutTask = await _dioClient.delete(logoutUri,
          data: {}).timeout(Duration(seconds: _options.timeout));

      // Clear PxSessionId
      _pxSessionID = "";

      /// It's important to close each client when it's done being used; failing to do so can cause the Dart process to hang.
      _dioClient.close();

      return logoutTask;
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.toString(), statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
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

    _dioClient.options.headers["pxsessionid"] = pxsessionid;
    _dioClient.options.contentType = Headers.jsonContentType;
    _dioClient.options.responseType = ResponseType.json;

    try {
      final getUri = _getUriUrl(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
              .toString(),
          null);

      var resp = await _dioClient.get(
        getUri,
        queryParameters: params,
      );
      switch (resp.statusCode) {
        case 200:
          // Update PxSessionId
          setPxSessionId(resp.headers.value("pxsessionid"));
          return resp;
        default:
          throw Result.error(
              ProffixException(body: resp.data, statusCode: resp.statusCode));
      }
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
    }
  }

  /// Utility method to make http post call
  @override
  Future<Response> post({
    String endpoint = '',
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();
    _dioClient.options.contentType = Headers.jsonContentType;
    _dioClient.options.responseType = ResponseType.json;

    _dioClient.options.headers['PxSessionId'] = pxsessionid;

    try {
      final postUri = _getUriUrl(
          buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
              .toString(),
          params);

      var resp = await _dioClient.post(postUri, data: data);
      if (resp.statusCode == null ||
          (resp.statusCode! < 200 && resp.statusCode! > 300)) {
        throw ProffixException(body: resp.data, statusCode: resp.statusCode);
      } else {
        // Update PxSessionId
        setPxSessionId(resp.headers.value("pxsessionid"));
        return resp;
      }
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
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

    _dioClient.options.headers['content-type'] = 'application/json';
    _dioClient.options.headers['PxSessionId'] = pxsessionid;

    try {
      var resp = await _dioClient
          .patch(
              buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, endpoint]),
              data: jsonEncode(data))
          .timeout(Duration(seconds: _options.timeout));

      if (resp.statusCode == null ||
          (resp.statusCode! < 200 || resp.statusCode! > 300)) {
        throw ProffixException(body: resp.data, statusCode: resp.statusCode);
      } else {
        // Update PxSessionId
        setPxSessionId(resp.headers.value("pxsessionid"));
        return resp;
      }
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
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

    _dioClient.options.headers['content-type'] = 'application/json';
    _dioClient.options.headers['PxSessionId'] = pxsessionid;

    try {
      var resp = await _dioClient
          .put(
              buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, endpoint]),
              data: json.encode(data))
          .timeout(Duration(seconds: _options.timeout));
      if (resp.statusCode == null ||
          (resp.statusCode! < 200 || resp.statusCode! > 300)) {
        throw ProffixException(body: resp.data, statusCode: resp.statusCode);
      } else {
        // Update PxSessionId
        setPxSessionId(resp.headers.value("pxsessionid"));
        return resp;
      }
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
    }
  }

  /// Utility method to make http delete call
  @override
  Future<Response> delete({String endpoint = ''}) async {
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["content-type"] = "application/json";
    _dioClient.options.headers["PxSessionId"] = pxsessionid;

    try {
      var resp = await _dioClient
          .delete(
            buildUriPx(
                restURL, [_options.apiPrefix, _options.version, endpoint]),
          )
          .timeout(Duration(seconds: _options.timeout));

      // Update PxSessionId
      setPxSessionId(resp.headers.value("pxsessionid"));
      return resp;
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
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

    _dioClient.options.headers["content-type"] = "application/json";
    _dioClient.options.headers["PxSessionId"] = pxsessionid;

    // Set ResponseType to bytes
    _dioClient.options.responseType = ResponseType.bytes;

    try {
      data ??= {};
      var listDownload =
          await post(endpoint: "PRO/Liste/$listeNr/generieren", data: data);

      String? downloadLocation = listDownload.headers.value("location");
      setPxSessionId(listDownload.headers.value("pxsessionid"));

      String downloadURI = Uri.parse(downloadLocation!).toString();

      _dioClient.options.headers["PxSessionId"] = pxsessionid;

      return await _dioClient.get(downloadURI,
          options: Options(responseType: ResponseType.bytes));
    } catch (e) {
      if (e is DioException) {
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
    }
  }

  /// Utility method to directly download a file from PRO/Datei
  @override
  Future<Response> downloadFile(
      {required String dateiNr, Map<String, dynamic>? params}) async {
    try {
      String pxsessionid = await getPxSessionId();

      final downloadUri = _getUriUrl(
          buildUriPx(restURL,
              [_options.apiPrefix, _options.version, "PRO/Datei/$dateiNr"]),
          params);

      _dioClient.options.headers["PxSessionId"] = pxsessionid;

      return await _dioClient.get(downloadUri,
          data: {},
          options: Options(
            responseType: ResponseType.bytes,
          ));
    } catch (e) {
      if (e is ProffixException) {
        rethrow;
      } else if (e is HttpException) {
        throw ProffixException(body: e.message, statusCode: 0);
      } else {
        if (e is List<int>) {
          throw ProffixException(body: utf8.decode(e), statusCode: 0);
        } else {
          throw ProffixException(body: e, statusCode: 0);
        }
      }
    }
  }

  /// Utility method to directly upload a file
  @override
  Future<String> uploadFile({String? fileName, required Uint8List data}) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();
    _dioClient.options.contentType = Headers.jsonContentType;
    _dioClient.options.responseType = ResponseType.json;

    _dioClient.options.headers['PxSessionId'] = pxsessionid;
    _dioClient.options.headers["content-type"] = "application/octet-stream";
    _dioClient.options.contentType = "application/octet-stream";
    _dioClient.options.headers['Content-Length'] = data.length;

    Map<String, dynamic> params = {"filename": fileName};
    try {
      final postUri = _getUriUrl(
          buildUriPx(
                  restURL, [_options.apiPrefix, _options.version, "PRO/Datei"])
              .toString(),
          fileName != null ? params : null);

      var resp = await _dioClient.post(postUri,
          // onSendProgress: (count, total) => {print(count)},
          options: Options(
              receiveTimeout: Duration(minutes: 2),
              sendTimeout: Duration(minutes: 2)),
          data: Stream.fromIterable(data.map((e) => [e])));
      if (resp.statusCode == null ||
          (resp.statusCode! < 200 && resp.statusCode! > 300)) {
        throw ProffixException(body: resp.data, statusCode: resp.statusCode);
      } else {
        // Update PxSessionId
        setPxSessionId(resp.headers.value("pxsessionid"));
        String dateiNr = ProffixHelpers().convertLocationIdString(resp.headers);
        return dateiNr;
      }
    } catch (e) {
      if (e is ProffixException) {
        //handle DioError here by error type or by error code
        rethrow;
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
    }
  }

  /// Utility method to check valid credentials
  @override
  Future<Response> check() async {
    // return await call('get', path: path, headers: headers, params: params);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["content-type"] = "application/json";
    _dioClient.options.headers["PxSessionId"] = pxsessionid;

    try {
      Map<String, String> params = {"Limit": "1", "Fields": "AdressNr"};
      final getUri = _getUriUrl(
          buildUriPx(restURL,
              [_options.apiPrefix, _options.version, "ADR/Adresse"]).toString(),
          params);

      var resp = await _dioClient
          .get(getUri)
          .timeout(Duration(seconds: _options.timeout));

      switch (resp.statusCode) {
        case 200:

          // Update PxSessionId
          setPxSessionId(resp.headers.value("pxsessionid"));
          return resp;
        default:
          throw Result.error(
              ProffixException(body: resp.data, statusCode: resp.statusCode));
      }
    } catch (e) {
      if (e is DioException) {
        //handle DioError here by error type or by error code
        throw ProffixException(
            body: e.response, statusCode: e.response?.statusCode ?? 0);
      } else {
        throw ProffixException(body: e.toString(), statusCode: 0);
      }
    }
  }

  /// This method was taken from https://github.com/Ephenodrom/Dart-Basic-Utils/blob/master/lib/src/HttpUtils.dart#L279
  static String _getUriUrl(String url, Map<String, dynamic>? queryParameters) {
    if (queryParameters != null && queryParameters.isEmpty) {
      return Uri.parse(url).toString();
    }
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: queryParameters).toString();
  }

  /// Manually sets the PxSessionId
  void setPxSessionId(String? pxsessionid) {
    _pxSessionID = pxsessionid!;
  }

  /// Returns the used PxSessionId
  Future<String> getPxSessionId() async {
    if (_pxSessionID == "") {
      try {
        var lgn = await login(
            username: username,
            password: password,
            restURL: restURL,
            database: database,
            options: _options,
            modules: modules);

        if (lgn.statusCode != 201) {
          throw Result.error(
              ProffixException(body: lgn.data, statusCode: lgn.statusCode));
        }

        String pxsessionid = lgn.headers.value("pxsessionid").toString();
        return pxsessionid;
      } catch (e) {
        if (e is DioException) {
          //handle DioError here by error type or by error code
          throw ProffixException(
              body: e.response, statusCode: e.response?.statusCode ?? 0);
        } else {
          throw ProffixException(body: e.toString(), statusCode: 0);
        }
      }
    }
    return _pxSessionID;
  }
}
