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

  /// Optional: enable client-side caching of PxSessionId
  bool enableSessionCaching;

  /// Optional: async callback to load a cached PxSessionId
  Future<String?> Function()? loadSessionId;

  /// Optional: async callback to persist a PxSessionId
  Future<void> Function(String)? saveSessionId;

  /// Optional: async callback to clear the cached PxSessionId
  Future<void> Function()? clearSessionId;

  ProffixRestOptions(
      {this.key = "",
      this.version = "v4",
      this.apiPrefix = "pxapi",
      this.loginEndpoint = "PRO/Login",
      this.userAgent = "DartWrapper",
      this.timeout = 15,
      this.batchsize = 200,
      this.log = false,
      this.volumeLicence = false,
      this.enableSessionCaching = false,
      this.loadSessionId,
      this.saveSessionId,
      this.clearSessionId});
}
