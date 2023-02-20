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
  Future<Either<Response, ProffixException>> get({
    required String endpoint,
    Map<String, dynamic>? params = const {},
  });

  /// An alias of ProffixClient.call('post')
  Future<Either<Response, ProffixException>> post({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('patch')
  Future<Either<Response, ProffixException>> patch({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('put')
  Future<Either<Response, ProffixException>> put({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('delete')
  Future<Either<Response, ProffixException>> delete({
    required String endpoint,
  });

  /// An alias of ProffixClient.getList('getList')
/*   Future<Either<Response, ProffixException>> getList({
    required int listeNr,
    Map<String, dynamic>? data,
  }); */

  /// An alias of ProffixClient.getList('getList')
  Future<Either<Response, ProffixException>> check();
}
