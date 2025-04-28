import 'dart:async';

import 'package:http/http.dart' as http;

import 'oauth2_rest_client.dart';

class OAuthRestClientF implements OAuth2RestClient
{
  final client = http.Client();

  String? accessToken;
  final Future<String?> Function()? refreshToken;
  
  OAuthRestClientF({this.accessToken, this.refreshToken});

  Map<String, String>? combineHeader(Map<String, String>? headers, String key, String? value)
  {
    if (value == null) return headers;

    return 
    {
      key : value,
      if (headers != null) ...headers,
    };
  }
  
  @override
  Future<RestResponse> get(String url, {Map<String, String>? queryParams, Map<String, String>? headers}) async 
  {
    final lastHeaders = combineHeader(headers, "Authorization", "Bearer $accessToken");
    final uri = Uri.parse(url).replace(queryParameters: queryParams ?? {});

    var response = await client.get(uri, headers: lastHeaders);
    if (response.statusCode == 401 && refreshToken != null) 
    {
      int retry = int.tryParse(headers?["X-Retry"] ?? "") ?? 0;
      if (retry < 3)
      {
        var newToken = await refreshToken!();
        if (newToken?.isNotEmpty ?? false)
        {
          accessToken = newToken;
          var retryHeader = combineHeader(headers, "X-Retry", (retry + 1).toString());
          return get(url, queryParams: queryParams, headers:retryHeader);
        }
      }
    }
    return ResponseF(response);
  }

  @override
  Future<void> delete(String url, {Map<String, String>? queryParams, Map<String, String>? headers}) async 
  {
    final lastHeaders = combineHeader(headers, "Authorization", "Bearer $accessToken");
    final uri = Uri.parse(url).replace(queryParameters: queryParams ?? {});
    await http.delete(uri, headers: lastHeaders);
  }
}

class ResponseF implements RestResponse
{
  final http.Response response;
  ResponseF(this.response);
  
  @override
  String get body => response.body;
  
  @override
  int? get statusCode => response.statusCode;
}