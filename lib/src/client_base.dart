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
    required String path,
    Map<String, String> headers = const {},
    Map<String, dynamic> params = const {},
  });

  /// An alias of ProffixClient.call('post')
  Future<Response> post({
    required String path,
    Map<String, String>? headers = const {},
    Map<String, dynamic>? data,
  });
}
