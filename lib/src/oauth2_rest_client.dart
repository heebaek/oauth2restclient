abstract interface class OAuth2RestClient
{
  Future<RestResponse> get(String url, {Map<String, String>? queryParams, Map<String, String>? headers});
  Future<void> delete(String url, {Map<String, String>? queryParams, Map<String, String>? headers});
}

abstract interface class RestResponse
{
  int? get statusCode;
  String get body;
}