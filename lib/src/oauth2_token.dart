import 'dart:convert';

class OAuth2Token
{
  final String accessToken;
  final String refreshToken;
  final String userName;
  final String iss;
  final DateTime expiry;
  final DateTime refreshTokenExpiry;

  bool get timeToRefresh
  {
    var now = DateTime.now().toUtc();
    
    return now.isAfter(expiry.subtract(Duration(minutes: 5)));
  }

  bool get canRefresh
  {
    if (refreshToken.isEmpty) return false;
    var now = DateTime.now().toUtc();
    return now.isBefore(refreshTokenExpiry.subtract(Duration(minutes: 5)));
  }

  OAuth2Token({
    required this.accessToken,
    required this.refreshToken,
    required this.userName,
    required this.iss,
    required this.expiry,
    required this.refreshTokenExpiry,
  });

  factory OAuth2Token.fromJsonString(String jsonResponse) 
  {
    final jsonMap = jsonDecode(jsonResponse);
    return OAuth2Token.fromJson(jsonMap);
  }

  String toJsonString()
  {
    var json = toJson();
    return jsonEncode(json);
  }

  static Map<String, dynamic> _tryDecodeIdToken(String? idToken)
	{
    if (idToken?.isEmpty ?? true) return {};
     
    final parts = idToken!.split('.');
		if (parts.length != 3) {
			throw Exception("🚨 ID Token 형식 오류");
		}
		final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
		return jsonDecode(payload);
	}

  static void _parseToken(Map<String, dynamic> json)
  {
    if (!json.containsKey("expiry"))
    {
      if (json.containsKey("expires_in"))
      {
        json["expiry"] = DateTime.now().toUtc()
					.add(Duration(seconds: json["expires_in"]))
					.toIso8601String();
      }
      else
      {
        json["expiry"] = "9999-12-31T23:59:59.999Z";
      }
    }
		
    if (!json.containsKey("refresh_token_expiry"))
    {
      if (json.containsKey("refresh_token_expires_in"))
      {
        json["refresh_token_expiry"] = DateTime.now().toUtc()
					.add(Duration(seconds: json["refresh_token_expires_in"]))
					.toIso8601String();
      }
      else
      {
        json["refresh_token_expiry"] = "9999-12-31T23:59:59.999Z";
      }
    }

    if (!json.containsKey("userName") || !json.containsKey("iss"))
    {
      var idToken = _tryDecodeIdToken(json["id_token"]);
      json["userName"] = idToken["email"] ?? idToken["sub"] ?? "";
      json["iss"] = idToken["iss"] ?? "";      
    }
   
    if (!json.containsKey("refresh_token"))
    {
      json["refresh_token"] = "";
    }
  }

  factory OAuth2Token.fromJson(Map<String, dynamic> json) {
    _parseToken(json);
    return OAuth2Token(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      userName: json['userName'],
      iss: json['iss'],
      expiry: DateTime.parse(json['expiry']),
      refreshTokenExpiry: DateTime.parse(json['refresh_token_expiry']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'userName': userName,
      'iss': iss,
      'expiry': expiry.toIso8601String(),
      'refresh_token_expiry': refreshTokenExpiry.toIso8601String(),
    };
  }
}