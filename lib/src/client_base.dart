import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../dart_proffix_rest.dart';

abstract class BaseProffixClient {
  /// Extended by [ProffixClient]
  BaseProffixClient();

  // UTILITIES

  /// Utility method to create an http call
  // Future<Response> call(
  //   String method, {
  //   required String path,
  //   Map<String, String> headers = const {},
  //   Map<String, dynamic> params = const {},
  // });

  /// An alias of ProffixClient.call('get')
  Future<Either<ProffixException, Response>> get({
    required String endpoint,
    Map<String, dynamic>? params = const {},
  });

  /// An alias of ProffixClient.call('post')
  Future<Either<ProffixException, Response>> post({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('patch')
  Future<Either<ProffixException, Response>> patch({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('put')
  Future<Either<ProffixException, Response>> put({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('delete')
  Future<Either<ProffixException, Response>> delete({
    required String endpoint,
  });

  /// An alias of ProffixClient.getList('getList')
  Future<Either<ProffixException, Response>> getList({
    required int listeNr,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.getList('getList')
  Future<Either<ProffixException, Response>> check();
}
