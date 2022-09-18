class ProffixRestOptions {
  String key;
  String version;
  String apiPrefix;
  String loginEndpoint;
  String userAgent;
  int timeout = 30;
  int batchsize;
  bool log;
  bool volumeLicence;

  ProffixRestOptions(
      {this.key = "",
      this.version = "v4",
      this.apiPrefix = "pxapi",
      this.loginEndpoint = "PRO/Login",
      this.userAgent = "DartWrapper",
      this.timeout = 15,
      this.batchsize = 200,
      this.log = false,
      this.volumeLicence = false});
}
