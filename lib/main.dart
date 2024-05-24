import 'dart:html';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keycloak_flutter/keycloak_flutter.dart';

late KeycloakService keycloakService;

void main() async {
  keycloakService = KeycloakService(KeycloakConfig(
    url: 'https://rhsso-dev.grupomateus.com.br/auth',
    realm: 'grupomateus',
    clientId: 'gmsuite',
  ));
  await keycloakService.init(
    initOptions: KeycloakInitOptions(
      onLoad: 'check-sso',
      responseMode: 'query',
      silentCheckSsoRedirectUri:
          '${window.location.origin}/silent-check-sso.html',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Keycloak Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  KeycloakProfile? _keycloakProfile;

  void _login() {
    keycloakService.login(KeycloakLoginOptions(
      redirectUri: '${window.location.origin}',
    ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      keycloakService.keycloakEventsStream.listen((event) async {
        print(event);
        if (event.type == KeycloakEventType.onAuthSuccess) {
          _keycloakProfile = await keycloakService.loadUserProfile();
        } else {
          _keycloakProfile = null;
        }
        setState(() {});
      });
      if (keycloakService.authenticated) {
        _keycloakProfile = await keycloakService.loadUserProfile(false);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sample'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await keycloakService.logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.red)),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Text(
                'Ensure you use the sample client included in this example app.',
                style: TextStyle(color: Colors.red),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Welcome ${_keycloakProfile?.username ?? 'Guest'}',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 20),
            if (_keycloakProfile?.username == null)
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            SizedBox(
              height: 20,
            ),
            if (_keycloakProfile?.username != null)
              ElevatedButton(
                onPressed: () async {
                  print('refreshing token');
                  await keycloakService.updateToken(1000).then((value) {
                    print(value);
                  }).catchError((onError) {
                    print(onError);
                  });
                },
                child: Text(
                  'Refresh token',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _login,
        tooltip: 'Login',
        child: Icon(Icons.login),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MyHomePage(),
    ),
  ],
);
