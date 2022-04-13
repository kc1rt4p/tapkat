import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/screens/login/email_verification_screen.dart';
import 'package:tapkat/screens/login/login_screen.dart';
import 'package:tapkat/screens/root/root_screen.dart';
import 'package:tapkat/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authBloc = AuthBloc();
  final _barterBloc = BarterBloc();
  StreamSubscription<TapkatFirebaseUser?>? _userStream;
  TapkatFirebaseUser? _user;
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  @override
  void initState() {
    _authBloc.add(InitializeAuth());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => _authBloc,
        ),
        BlocProvider<BarterBloc>(
          create: (context) => _barterBloc,
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _authBloc,
            listener: (context, state) {
              if (state is AuthInitialized) {
                _userStream = state.stream.listen((user) {
                  if (user.user != null) {
                    setState(() {
                      _user = user;
                    });
                  }
                });
              }

              if (state is AuthSignedIn) {
                setState(() {
                  _user = TapkatFirebaseUser(state.user);
                });
              }

              if (state is AuthSignedOut) {
                _userStream!.cancel();
                setState(() {
                  _user = null;
                });
              }
            },
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Tapkat',
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: Colors.transparent,
            ),
          ),
          home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data != null) {
                    final user = snapshot.data;
                    if (user!.emailVerified) {
                      return RootScreen();
                    } else {
                      return EmailVerificationScreen();
                    }
                  }
                }

                return LoginScreen();
              }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userStream?.cancel();
    super.dispose();
  }
}
