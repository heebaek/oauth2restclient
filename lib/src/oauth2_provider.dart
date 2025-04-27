class OAuth2Provider
{
  final String clientId;
  final String? clientSecret;
  final String redirectUri;
  final List<String> scopes;
  final String authEndpoint;
  final String tokenEndpoint;

  OAuth2Provider({
    required this.clientId,
    this.clientSecret,
    required this.redirectUri,
    required this.scopes,
    required this.authEndpoint,
    required this.tokenEndpoint
  });

  String getAuthUrl() {
    return "$authEndpoint"
        "?client_id=$clientId"
        "&redirect_uri=$redirectUri"
        "&response_type=code"
        "&scope=${scopes.join('%20')}"
        "&access_type=offline"
        "&prompt=consent";
  }
}