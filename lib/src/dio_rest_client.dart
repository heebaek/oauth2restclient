import 'dart:async';

import 'package:dio/dio.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

import 'oauth2_rest_client.dart';

class DioRestClient implements OAuth2RestClient
{
  final Dio _dio = Dio();

  String? accessToken;
  
  final Future<String?> Function()? refreshToken;
    
  DioRestClient(this.accessToken, this.refreshToken) 
  {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) 
      {
        options.headers['Authorization'] = 'Bearer $accessToken';
        return handler.next(options);
      },
      onError: (DioException e, handler) async 
      {
        if (e.response?.statusCode == 401 && refreshToken != null)
        {
          // onError에서 retryCount 확인 및 설정
          int retryCount = e.requestOptions.extra['retryCount'] ?? 0;
          if (retryCount == 0)
          {
            e.requestOptions.extra['retryCount'] = retryCount + 1;
          
            // 토큰 갱신 및 재시도 로직...
            var newToken = await refreshToken?.call();
            if (newToken != null)
            {
              accessToken = newToken;
            }

            var response = await _dio.fetch(e.requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(e);
      })
    );
  }
  
  @override
  Future<void> delete(String url, {Map<String, String>? queryParams}) async
  {
    await _dio.delete(
      url,
      queryParameters: queryParams,
    );
  }
  
  @override
  Future<RestResponse> get(String url, {Map<String, String>? queryParams}) async 
  {
    var response = await _dio.get(url, queryParameters: queryParams, options: Options(responseType: ResponseType.plain));
    return DioResponse(response);
  }
}

class DioResponse implements RestResponse
{
  final String _body;
  final int? _statusCode;
  DioResponse(Response response) : _body = response.data as String, _statusCode = response.statusCode;
  
  @override
  String get body => _body;
  
  @override
  int? get statusCode => _statusCode;
}