class ProffixRestOptions {
  String key;
  String version;
  String apiPrefix;
  String loginEndpoint;
  String userAgent;
  int timeout = 30;
  bool verifySSL;
  int batchsize;
  bool log;
  bool volumeLicence;

  ProffixRestOptions(
      {this.key = "",
      this.version = "v4",
      this.apiPrefix = "/pxapi/",
      this.loginEndpoint = "PRO/Login",
      this.userAgent = "DartWrapper",
      this.timeout = 200,
      this.verifySSL = true,
      this.batchsize = 200,
      this.log = false,
      this.volumeLicence = false});
}
