import 'dart:async';
import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
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

import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/utilities/dialog_message.dart';

_loadUserLocation() async {
  try {
    final per1 = await Permission.location.request();
    final per2 =
        await geoLocator.GeolocatorPlatform.instance.isLocationServiceEnabled();
    if (per1 != PermissionStatus.denied && per2) {
      final userLoc = await geoLocator.Geolocator.getCurrentPosition();
      final places = await geoCoding.placemarkFromCoordinates(
          userLoc.latitude, userLoc.longitude);
      final place = places.first;
      application.currentCountry = place.isoCountryCode;
      print(
          '-=======< using device location: ${userLoc.latitude}, ${userLoc.longitude}');
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

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  application.deviceId = await ApiService.getDeviceId();
  application.deviceName = await ApiService.getDeviceName();
  await _loadUserLocation();

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
    initLogs();

    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  initLogs() async {
    await FlutterLogs.initLogs(
      logLevelsEnabled: [
        LogLevel.INFO,
        LogLevel.WARNING,
        LogLevel.ERROR,
        LogLevel.SEVERE,
      ],
      timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
      directoryStructure: DirectoryStructure.FOR_DATE,
      logTypesEnabled: ["device", "network", "errors"],
      logFileExtension: LogFileExtension.LOG,
      logsWriteDirectoryName: "TapKat_logs",
      logsExportDirectoryName: "TapKat_logs/Exported",
      debugFileOperations: true,
      isDebuggable: true,
    );
    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterLogs.logError(
        'ERROR',
        'error ${details.stack}',
        details.exception.toString(),
      );
      final timeString = DateTime.now().millisecondsSinceEpoch.toString();
      FlutterLogs.logToFile(
        logFileName: timeString,
        overwrite: false,
        logMessage:
            'ERROR: ${details.exception.toString()}\n\n\nSTACK TRACE: ${details.stack.toString()}\n\n\n${details.stackFilter}',
      );
      FlutterLogs.exportAllFileLogs();
      FlutterError.presentError(details);

      // Directory? externalDirectory;

      //       if (Platform.isIOS) {
      //         externalDirectory = await getApplicationDocumentsDirectory();
      //       } else {
      //         externalDirectory = await getExternalStorageDirectory();
      //       }

      final email = Email(
        body:
            'CURRENT SCREEN: ${application.currentScreen}\n\nDEVICE NAME: ${application.deviceName}\n\nDEVICE ID: ${application.deviceId}\n\n\nERROR: ${details.exception.toString()}\n\n\nSTACK TRACE: ${details.stack.toString()}\n\n\nSUMMARY: ${details.summary}',
        subject: 'TapKat Error - $timeString',
        recipients: [
          'tapkat_support@cloud-next.com.au',
        ],
        cc: [],
        bcc: [],
        isHTML: false,
      );

      // await FlutterEmailSender.send(email);

      SchedulerBinding.instance!.addPostFrameCallback((_) {
        DialogMessage.show(
          navigatorKey.currentContext!,
          message:
              'There was an unexpected error.\n\nClick on “Send Logs” to send the error logs to TapKat support via email.\n\nNone of your personally identifiable private information will be sent to TapKat.',
          buttonText: 'Send Logs',
          firstButtonClicked: () async {
            await FlutterEmailSender.send(email);
          },
          secondButtonText: 'Cancel',
        );
      });

      if (kReleaseMode) exit(1);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (application.currentUser != null)
          _authBloc.add(UpdateOnlineStatus(true));
        break;
      default:
        if (application.currentUser != null)
          _authBloc.add(UpdateOnlineStatus(false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _userStream?.cancel();
    _barterBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
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
                    _userModel = application.currentUserModel;
                  });
                }

                if (state is AuthSignedOut) {
                  _userStream!.cancel();
                  setState(() {
                    _user = null;
                    _userModel = null;
                  });
                }
              },
            ),
          ],
          child: DevicePreview(
            enabled: false,
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
    } catch (e) {
      print('____==== ERROR!!!!');
      return Container();
    }
  }
}
