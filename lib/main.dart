import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/screens/login/email_verification_screen.dart';
import 'package:tapkat/screens/login/login_screen.dart';
import 'package:tapkat/screens/root/root_screen.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:flutter_dotenv/flutter_dotenv.dart';

_loadUserLocation() async {
  try {
    final per1 = await Permission.location.request();
    final per2 =
        await geoLocator.GeolocatorPlatform.instance.isLocationServiceEnabled();
    if (per1 != PermissionStatus.denied && per2) {
      final userLoc = await geoLocator.Geolocator.getCurrentPosition();
      print('-=======< using device location');
      application.currentUserLocation = LocationModel(
        latitude: userLoc.latitude,
        longitude: userLoc.longitude,
      );
    }
  } catch (e) {
    print('Unable to get current device location::::::: ${e.toString()}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  application.deviceId = await ApiService.getDeviceId();
  await _loadUserLocation();

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthBloc _authBloc;
  late BarterBloc _barterBloc;
  StreamSubscription<TapkatFirebaseUser?>? _userStream;
  TapkatFirebaseUser? _user;
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  UserModel? _userModel;

  @override
  void initState() {
    _authBloc = AuthBloc();
    _barterBloc = BarterBloc();

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
                    _authBloc.add(GetCurrentuser());
                    setState(() {
                      _user = user;
                    });
                  }
                });
              }

              if (state is GetCurrentUsersuccess) {
                setState(() {
                  _userModel = state.userModel;
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
        child: DevicePreview(
          enabled: kDebugMode,
          builder: (context) => MaterialApp(
            useInheritedMediaQuery: true,
            locale: DevicePreview.locale(context),
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
                    if (snapshot.data != null && _userModel != null) {
                      return RootScreen();
                    }
                  }

                  return LoginScreen();
                }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userStream?.cancel();
    _barterBloc.close();
    super.dispose();
  }
}
