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
  Future<Response> get({
    required String endpoint,
    Map<String, dynamic>? params = const {},
  });

  /// An alias of ProffixClient.call('post')
  Future<Response> post({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('patch')
  Future<Response> patch({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('put')
  Future<Response> put({
    required String endpoint,
    Map<String, dynamic>? data,
  });

  /// An alias of ProffixClient.call('delete')
  Future<Response> delete({
    required String endpoint,
  });

  /// An alias of ProffixClient.getList('getList')
/*   Future<Response> getList({
    required int listeNr,
    Map<String, dynamic>? data,
  }); */
}
