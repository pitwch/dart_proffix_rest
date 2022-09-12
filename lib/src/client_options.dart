class ProffixRestOptions {
  String? key;
  String? version = "v4";
  String? apiPrefix = "/pxapi/";
  String? loginEndpoint = "PRO/Login";
  String? userAgent = "DartWrapper";
  int? timeout = 0;
  bool? verifySSL = true;
  int? batchsize = 200;
  bool? log = false;
  bool? volumeLicence = false;

  ProffixRestOptions(
      this.key,
      this.version,
      this.apiPrefix,
      this.loginEndpoint,
      this.userAgent,
      this.timeout,
      this.verifySSL,
      this.log,
      this.volumeLicence);
}
