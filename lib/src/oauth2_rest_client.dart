abstract interface class OAuth2RestClient
{
  Future<RestResponse> get(String url, {Map<String, String>? queryParams});
  Future<void> delete(String url, {Map<String, String>? queryParams});
}

abstract interface class RestResponse
{
  int? get statusCode;
  String get body;
}