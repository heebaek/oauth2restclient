import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../oauth2_cancel_token.dart';
import '../exception/oauth2_exception.dart';

abstract interface class OAuth2RestResponse
{
  int? get statusCode;
  String? headerValue(String header);
  void ensureSuccess();
  bool get isSuccess;
  
  Stream<List<int>> get bodyStream;
  Future<String> readAsString();
  Future<List<int>> readAsBytes();

  Future<void> copyTo(StreamSink<List<int>> sink, {void Function(int uploadedBytes, int? totalBytes)? onProgress, OAuth2CancelToken? token});

  Future<void> dispose();
}

class OAuth2RestResponseF implements OAuth2RestResponse 
{
  final HttpClientResponse _response;
  bool _disposed = false;

  OAuth2RestResponseF(this._response);

  @override
  bool get isSuccess => _response.statusCode >= 200 && _response.statusCode < 300;
  
  @override
  void ensureSuccess()
  {
    if (!isSuccess) throw HttpException('HTTP request failed, statusCode=$statusCode');
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('Response already disposed.');
    }
  }

  @override
  int get statusCode => _response.statusCode;

  @override
  Stream<List<int>> get bodyStream {
    _ensureNotDisposed();
    return _response;
  }

  @override
  Future<String> readAsString() async {
    _ensureNotDisposed();
    final body = await utf8.decodeStream(_response);
    await dispose();
    return body;
  }

  @override
  Future<List<int>> readAsBytes() async {
    _ensureNotDisposed();

    final chunks = await _response.toList(); // List<List<int>>
    final body = <int>[];
    for (final chunk in chunks) {
      body.addAll(chunk);
    }
    await dispose();
    return body;
  }

  
  @override
  Future<void> copyTo(StreamSink<List<int>> sink, {void Function(int uploadedBytes, int? totalBytes)? onProgress, OAuth2CancelToken? token}) async
  {
    _ensureNotDisposed();
    if (onProgress != null) 
    {
      int downloaded = 0;
      int? totalLength = int.tryParse(headerValue("Content-Length") ?? "");
      await for (final chunk in bodyStream) 
      {
        if (token?.isCancelled ?? false) 
        {
          throw OAuth2ExceptionF.canceled(message: token?.reason ?? 'Cancelled by user');
        }
        sink.add(chunk);
    
        downloaded += chunk.length;
        onProgress.call(downloaded, totalLength);
      }
    }
    else
    {
      await bodyStream.pipe(sink);
    }
    await dispose();
  }

  @override
  Future<void> dispose() async {
    if (!_disposed) {
      try {
        await _response.drain();
      } catch (_) {
        // 무시
      }
      _disposed = true;
    }
  }
  
  @override
  String? headerValue(String header) => _response.headers.value(header);

}