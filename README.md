<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

OAuth2RestClient
A Dart/Flutter package that simplifies OAuth2 authentication and REST API interactions with automatic token management.

## Features

OAuth2 Authentication: Easy implementation of OAuth2 login flows

Account Management: Securely store and load user accounts and tokens

Automatic Token Handling: Transparently manages access tokens in request headers

Token Refresh: Automatically refreshes expired tokens when needed

Service Integration: Simplifies integration with REST APIs like Google Drive

## Usage

```dart
	final account = OAuth2Account();
		
	var google = Google
	(
		redirectUri: "com.googleusercontent.apps.95012368401-j0gcpfork6j38q3p8sg37admdo086gbs:/oauth2redirect",
		scopes: ['https://www.googleapis.com/auth/drive', "https://www.googleapis.com/auth/photoslibrary", "openid", "email"],
		clientId: dotenv.env["MOBILE_CLIENT_ID"]!
	);

	if (Platform.isMacOS)
	{
		google = Google
		(
			redirectUri: "http://localhost:8713/pobpob",
			scopes: ['https://www.googleapis.com/auth/drive', "https://www.googleapis.com/auth/photoslibrary", "openid", "email"],
			clientId: dotenv.env["DESKTOP_CLIENT_ID"]!,
			clientSecret:dotenv.env["DESKTOP_CLIENT_SECRET"]!,
		);
	}

	account.addProvider("google", google);


    var token = await account.newLogin("google");

	//or

	token = await account.loadAccount("google", "userName")

	var client = await account.createClient(token);

```