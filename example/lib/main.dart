import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final account = OAuth2Account(appPrefix: "oauth2restclientexample");
  final service = "microsoft";

  @override
  void initState() {
    super.initState();

    var dropbox = Dropbox(
      clientId: dotenv.env["DROPBOX_CLIENT_ID"]!,
      redirectUri: "aircomix://${dotenv.env["DROPBOX_CLIENT_ID"]!}/",
      scopes: [
        "account_info.read",
        "files.content.read",
        "files.content.write",
        "files.metadata.write",
        "files.metadata.read",
      ],
    );

    var google = Google(
      redirectUri:
          "com.googleusercontent.apps.95012368401-j0gcpfork6j38q3p8sg37admdo086gbs:/oauth2redirect",
      scopes: [
        'https://www.googleapis.com/auth/drive',
        "https://www.googleapis.com/auth/photoslibrary",
        "openid",
        "email",
      ],
      clientId: dotenv.env["MOBILE_CLIENT_ID"]!,
    );

    var ms = Microsoft(
      clientId: dotenv.env["ONEDRIVE_CLIENT_ID"]!,
      redirectUri: "aircomix://${dotenv.env["ONEDRIVE_CLIENT_ID"]!}/",
      scopes: [
        "User.Read",
        "Files.ReadWrite.All",
        "Files.Read.All",
        "openid",
        "email",
        "offline_access",
      ],
    );

    if (Platform.isMacOS) {
      google = Google(
        redirectUri: "http://localhost:8713/pobpob",
        scopes: [
          'https://www.googleapis.com/auth/drive',
          "https://www.googleapis.com/auth/photoslibrary",
          "openid",
          "email",
        ],
        clientId: dotenv.env["DESKTOP_CLIENT_ID"]!,
        clientSecret: dotenv.env["DESKTOP_CLIENT_SECRET"]!,
      );

      dropbox = Dropbox(
        clientId: dotenv.env["DROPBOX_CLIENT_ID"]!,
        redirectUri: "http://localhost:8713/pobpob",
        scopes: [
          "account_info.read",
          "files.content.read",
          "files.content.write",
          "files.metadata.write",
          "files.metadata.read",
        ],
      );

      ms = Microsoft(
        clientId: dotenv.env["ONEDRIVE_CLIENT_ID"]!,
        redirectUri: "http://localhost:8713/pobpob",
        scopes: [
          "User.Read",
          "Files.ReadWrite.All",
          "Files.Read.All",
          "openid",
          "email",
          "offline_access",
        ],
      );
    }

    account.addProvider(google);
    account.addProvider(dropbox);
    account.addProvider(ms);
  }

  int _counter = 0;

  Future<String> getEmail(OAuth2RestClient client, String service) async {
    if (service == "dropbox") {
      var response = await client.postJson(
        "https://api.dropboxapi.com/2/users/get_current_account",
      );
      return response["email"] as String;
    }

    if (service == "microsoft") {
      var response = await client.getJson(
        "https://graph.microsoft.com/v1.0/me",
      );
      return response["mail"] as String;
    }

    // Google
    var response = await client.getJson(
      "https://www.googleapis.com/oauth2/v3/userinfo",
    );
    return response["email"] as String;
  }

  void _incrementCounter() async {
    //var token = await account.any(service: service);
    //token ??= await account.newLogin(service);
    var token = await account.newLogin(service);
    if (token?.timeToLogin ?? false) {
      token = await account.forceRelogin(token!);
    }

    if (token == null) throw Exception("login first");
    var client = await account.createClient(token);

    // PUT 메서드 테스트
    //await testPutMethods(client);

    var email = await getEmail(client, service);
    debugPrint(email);

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
