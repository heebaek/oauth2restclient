import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'oauth2_provider.dart';
import 'oauth2_token.dart';

HttpServer? _server;

abstract interface class OAuth2Login
{
  Future<OAuth2Token?> login(OAuth2Provider provider);
}

class OAuth2LoginF implements OAuth2Login
{
  @override
  Future<OAuth2Token?> login(OAuth2Provider provider) async
  {
    if (Platform.isAndroid || Platform.isIOS) return loginFromMobile(provider);
    return loginFromDesktop(provider);
  }

  Future<OAuth2Token?> loginFromDesktop(OAuth2Provider provider) async 
  {  
    try
    {
      var uri = Uri.parse(provider.getAuthUrl());
      await launchUrl(uri); // ✅ 자동으로 브라우저 실행

      final bindUri = Uri.parse(provider.redirectUri);
      final host = bindUri.host; // 'localhost'
      final port = bindUri.port; // 8080 (또는 지정된 포트)
      final path = bindUri.path; // '/ca
    
      await _server?.close();      
      _server = await HttpServer.bind(host, port);

      await for (final request in _server!) 
      {
        // callback 경로 확인
        if (request.uri.path == path) 
        {
          // 코드 파라미터 추출
          var code = request.uri.queryParameters['code'];
          final response = await _exchangeCodeForToken(provider, code);

          if (response == null)
          {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
          else
          {
            // 성공 메시지를 브라우저에 표시
            request.response.headers.contentType = ContentType.html;
            request.response.write('''
              <!DOCTYPE html>
              <html>
              <head>
                <title>로그인 성공</title>
                <style>
                  body { font-family: Arial, sans-serif; text-align: center; padding-top: 50px; }
                  h1 { color: #4285f4; }
                  p { font-size: 16px; }
                </style>
              </head>
              <body>
                <h1>로그인 성공!</h1>
                <p>인증이 완료되었습니다. 이 창을 닫고 앱으로 돌아가세요.</p>
              </body>
              </html>
            ''');
            await request.response.close();

            return OAuth2Token.fromJsonString(response);
          }
        } 
        else 
        {
          // 잘못된 경로 처리
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      }
    }
    catch (e)
    {
      debugPrint(e.toString());
    }
    finally
    {
      await _server?.close();
      _server = null;
    }

    return null;        
  }

  Future<OAuth2Token?> loginFromMobile(OAuth2Provider provider) async 
  {
    var uri = Uri.parse(provider.getAuthUrl());
    if (!await canLaunchUrl(uri)) return null;
      
    Completer<String?> completer = Completer();
    final appLinks = AppLinks(); // AppLinks is singleton
    final sub = appLinks.uriLinkStream.listen((uri) async
    {	
      String? response;
      var code = uri.queryParameters["code"];      
      try
      {
        response = await _exchangeCodeForToken(provider, code);        
      }
      finally
      {
        if (!completer.isCompleted) 
        {
          completer.complete(response);
        }
      }
    });

    await launchUrl(uri); // ✅ 자동으로 브라우저 실행
    var response = await completer.future;
    sub.cancel();
    closeInAppWebView();

    if (response == null) return null;

    return OAuth2Token.fromJsonString(response);
  }

  Future<String?> _exchangeCodeForToken(OAuth2Provider provider, String? code) async 
  {
    if (code == null) return null;

    final response = await http.post(
      Uri.parse(provider.tokenEndpoint),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "client_id": provider.clientId,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": provider.redirectUri,
        if (provider.clientSecret != null) "client_secret": provider.clientSecret
      },
    );

    if (response.statusCode == 200) return response.body;
    return null; 
  }
}