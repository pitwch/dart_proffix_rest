import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'client_base.dart';
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
  Uri buildUriPx(String base, List<String>? frags) {
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
        pathSegments: cleanedFrags);
  }

  /// Utility method to Login
  Future<Either<Response, ProffixException>> login({
    required username,
    required password,
    required restURL,
    required database,
    required options,
    modules,
    dioClient,
  }) async {
    final loginUri = buildUriPx(
        restURL, [options.apiPrefix, options.version, options.loginEndpoint]);

    final loginBody = {
      "Benutzer": username,
      "Passwort": password,
      "Datenbank": {"Name": database},
      "Module": modules
    };
    _dioClient.options.headers['content-Type'] = 'application/json';

    var loginResponse = await _dioClient.post(
      loginUri.toString(),
      data: loginBody,
    );

    if (loginResponse.statusCode == 201) {
      _pxSessionID = loginResponse.headers.value("pxsessionid")!;
      return Left(loginResponse);
    } else {
      return Right(ProffixException(
          body: loginResponse.data.toString(),
          statusCode: loginResponse.statusCode));
    }
  }

  /// Do logout on Proffix REST-API and deletes PxSessionId
  Future<Response> logout({
    dioClient,
  }) async {
    _dioClient.options.headers["PxSessionId"] = _pxSessionID;
    _dioClient.options.headers["content-type"] = 'application/json';

    try {
      final logoutUri = buildUriPx(restURL,
          [_options.apiPrefix, _options.version, _options.loginEndpoint]);

      var logoutTask = await _dioClient.delete(logoutUri.toString());

      // Clear PxSessionId
      _pxSessionID = "";

      /// It's important to close each client when it's done being used; failing to do so can cause the Dart process to hang.
      _dioClient.close();

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
  Future<Either<Response, ProffixException>> get({
    String endpoint = '',
    Map<String, dynamic>? params,
  }) async {
    // return await call('get', path: path, headers: headers, params: params);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

    final getUri = _getUriUrl(
        buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
            .toString(),
        params!);

    var resp = await _dioClient.get(getUri.toString());

    if (resp.statusCode == 200) {
      // Update PxSessionId
      setPxSessionId(resp.headers.value("pxsessionid")!);
      return Left(resp);
    } else {
      return Right(
          ProffixException(body: resp.data, statusCode: resp.statusCode));
    }
  }

  /// Utility method to make http post call
  @override
  Future<Either<Response, ProffixException>> post({
    String endpoint = '',
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

    final postUri = _getUriUrl(
        buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
            .toString(),
        params);

    var resp = await _dioClient
        .post(postUri.toString(), data: json.encode(data))
        .timeout(Duration(seconds: _options.timeout));

    if (resp.statusCode != null &&
        (resp.statusCode! >= 200 || resp.statusCode! < 300)) {
      setPxSessionId(resp.headers.value("pxsessionid")!);

      return Left(resp);
    } else {
      return Right(
          ProffixException(body: resp.data, statusCode: resp.statusCode));
    }
  }

  /// Utility method to make http patch call
  @override
  Future<Either<Response, ProffixException>> patch({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

    var resp = await _dioClient
        .patch(
            buildUriPx(
                    restURL, [_options.apiPrefix, _options.version, endpoint])
                .toString(),
            data: jsonEncode(data))
        .timeout(Duration(seconds: _options.timeout));

    if (resp.statusCode != null &&
        (resp.statusCode! >= 200 || resp.statusCode! < 300)) {
      return Left(resp);
    } else {
      return Right(
          ProffixException(body: resp.data, statusCode: resp.statusCode));
    }
  }

  /// Utility method to make http put call
  @override
  Future<Either<Response, ProffixException>> put({
    String endpoint = '',
    Map<String, dynamic>? data,
  }) async {
    // return await call('post', path: path, headers: headers, data: data);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

    var resp = await _dioClient
        .put(
            buildUriPx(
                    restURL, [_options.apiPrefix, _options.version, endpoint])
                .toString(),
            data: json.encode(data))
        .timeout(Duration(seconds: _options.timeout));
    if (resp.statusCode != null &&
        (resp.statusCode! >= 200 || resp.statusCode! < 300)) {
      return Left(resp);
    } else {
      return Right(
          ProffixException(body: resp.data, statusCode: resp.statusCode));
    }
  }

  /// Utility method to make http delete call
  @override
  Future<Either<Response, ProffixException>> delete(
      {String endpoint = ''}) async {
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

    var resp = await _dioClient.delete(
        buildUriPx(restURL, [_options.apiPrefix, _options.version, endpoint])
            .toString());

    if (resp.statusCode != null &&
        (resp.statusCode! >= 200 || resp.statusCode! < 300)) {
      return Left(resp);
    } else {
      return Right(
          ProffixException(body: resp.data, statusCode: resp.statusCode));
    }
  }

  /* /// Utility method to directly get a list
  @override
  Future<Either<Response, ProffixException>> getList({
    int listeNr = 0,
    Map<String, dynamic>? data,
  }) async {
    // return await call('get', path: path, headers: headers, params: params);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

 
      data ??= {};
      var listDownload =
          await post(endpoint: "PRO/Liste/$listeNr/generieren", data: data);


      listDownload.fold((l) => {
      setPxSessionId(l.headers.value("pxsessionid")),
                String? downloadLocation = l.headers.value("location")

      }, (r) => 

         Right(r)
   );

      String? downloadLocation = listDownload.headers.["location"].toString();
      setPxSessionId(listDownload.headers["pxsessionid"].toString());
      Map<String, String> headersDownload = {};
      headersDownload.addAll({
        'PxSessionId': pxsessionid,
      });
      Uri downloadURI = Uri.parse(downloadLocation);
       var getDownload = await _dioClient.get(
        downloadURI.toString(),
      );

      if (getDownload.statusCode != null &&
        (getDownload.statusCode! >= 200 || getDownload.statusCode! < 300)) {
     return Left(getDownload.data);
    } else {
      return Right(
          ProffixException(body: getDownload.data, statusCode: getDownload.statusCode));
    }
  } */

  /// Utility method to check valid credentials
  @override
  Future<Either<Response, ProffixException>> check() async {
    // return await call('get', path: path, headers: headers, params: params);
    String pxsessionid = await getPxSessionId();

    _dioClient.options.headers["PxSessionId"] = pxsessionid;
    _dioClient.options.headers["content-type"] = 'application/json';

    Map<String, String> params = {"Limit": "1", "Fields": "AdressNr"};
    final getUri = _getUriUrl(
        buildUriPx(
                restURL, [_options.apiPrefix, _options.version, "ADR/Adresse"])
            .toString(),
        params);

    var resp = await _dioClient
        .get(
          getUri.toString(),
        )
        .timeout(Duration(seconds: _options.timeout));

    if (resp.statusCode == 200) {
      // Update PxSessionId
      setPxSessionId(resp.headers.value("pxsessionid")!);

      return Left(resp);
    } else {
      return Right(
          ProffixException(body: resp.data, statusCode: resp.statusCode));
    }
  }

  /// This method was taken from https://github.com/Ephenodrom/Dart-Basic-Utils/blob/master/lib/src/HttpUtils.dart#L279
  static Uri _getUriUrl(String url, Map<String, dynamic>? queryParameters) {
    if (queryParameters != null && queryParameters.isEmpty) {
      return Uri.parse(url);
    }
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: queryParameters);
  }

  /// Manually sets the PxSessionId
  void setPxSessionId(String? pxsessionid) {
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

      lgn.fold((l) => {setPxSessionId(l.headers.value("pxsessionid"))},
          (r) => {ProffixException(body: r.body, statusCode: r.statusCode)});
    }
    return _pxSessionID;
  }
}
