import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:notification_permissions/notification_permissions.dart'
    as notif;
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/root/barter/barter_transactions_screen.dart';
import 'package:tapkat/screens/root/home/home_screen.dart';
import 'package:tapkat/screens/root/profile/profile_screen.dart';
import 'package:tapkat/screens/root/wish_list/wish_list_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;

import 'bloc/root_bloc.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_stat_notif_icon');
final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(onDidReceiveLocalNotification: (a, b, c, d) {});
final MacOSInitializationSettings initializationSettingsMacOS =
    MacOSInitializationSettings();
final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    macOS: initializationSettingsMacOS);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
      '*****###***** *****###***** background message: ${message.notification!.body.toString()} *****###***** *****###*****');
}

class RootScreen extends StatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _screens = [
    HomeScreen(),
    WishListScreen(),
    BarterTransactionsScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;

  final _rootBloc = RootBloc();
  final _productBloc = ProductBloc();
  final _authBloc = AuthBloc();

  final _currentVerDate = DateTime(2022, 4, 9, 10);

  final _appConfig = new LocalStorage('app_config.json');

  @override
  void initState() {
    Permission.location.request();
    _loadUserLocation();
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  Future<void> _firebaseMessagingForegroundHandler(
      RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tapkat-2022',
      'tapkat_barter',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'ic_stat_notif_icon',
      color: kBackgroundColor,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    if (!application.chatOpened) {
      await flutterLocalNotificationsPlugin.show(0, message.notification!.title,
          message.notification!.body, platformChannelSpecifics,
          payload: '');
    } else
      return;
  }

  initNotifications() async {
    final _firebaseMessaging = FirebaseMessaging.instance;
    final _firstLoginDate = await _appConfig.getItem('first_login_date');
    final permissionStatus =
        await notif.NotificationPermissions.requestNotificationPermissions();
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('============= ${await FirebaseMessaging.instance.getToken()}');
    if (_firstLoginDate == null) {
      await _appConfig.setItem(
          'first_login_date', DateTime.now().millisecondsSinceEpoch.toString());

      if (application.currentUserModel!.pushalert == null) {
        _rootBloc.add(UpdateUserToken());
      }
    }

    if (permissionStatus == PermissionStatus.denied ||
        settings.authorizationStatus != AuthorizationStatus.authorized) return;

    print(
        '----------= PUSH ALERT: ${application.currentUserModel!.pushalert} =-----------');

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (val) {});

    FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    SizeConfig().init(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => _rootBloc,
          ),
          BlocProvider(
            create: (context) => _productBloc,
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _rootBloc,
              listener: (context, state) {
                if (state is MoveToTab) {
                  setState(() {
                    _currentIndex = state.index;
                  });
                }

                if (state is UpdateUserTokenSuccess) {
                  print('=== UPDATED USER TOKEN!!');
                }
              },
            ),
            BlocListener(
              bloc: _authBloc,
              listener: (context, state) {
                if (state is GetCurrentUsersuccess) {
                  initNotifications();
                }
              },
            )
          ],
          child: Container(
            color: kBackgroundColor,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      'Version 1.0.${DateFormat('yyMMddHH').format(_currentVerDate)}_D',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: kBackgroundColor,
                    child: _screens[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: showFab && _currentIndex == 0 || _currentIndex == 3
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: EdgeInsets.all(8.0),
              child: FloatingActionButton(
                heroTag: 'addProductBtn',
                backgroundColor: Color(0xFFBB3F03),
                child: Icon(Icons.add, size: 30.0),
                onPressed: _onAddTapped,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  _onAddTapped() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductAddScreen(),
      ),
    );

    setState(() {
      _currentIndex = 1;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _currentIndex = 3;
      });
    });
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: kToolbarHeight,
      color: Color(0xFFEBFBFF),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBottomNavItem(
              isActive: _currentIndex == 0,
              icon: Icons.home,
              index: 0,
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 1,
              icon: Icons.favorite,
              index: 1,
            ),
            Visibility(
              visible: _currentIndex == 0 || _currentIndex == 3,
              child: SizedBox(
                width: 50.0,
              ),
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 2,
              icon: Icons.repeat_outlined,
              index: 2,
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 3,
              icon: Icons.person,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildBottomNavItem({
    required IconData icon,
    required bool isActive,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          child: Icon(
            icon,
            color: isActive ? Color(0xFF94D2BD) : Colors.grey,
            size: isActive ? 30.0 : null,
          ),
        ),
      ),
    );
  }

  _loadUserLocation() async {
    if (await Permission.location.isDenied) return;
    if (!(await geoLocator.GeolocatorPlatform.instance
        .isLocationServiceEnabled())) return;
    final userLoc = await geoLocator.Geolocator.getCurrentPosition();
    application.currentUserLocation = LocationModel(
      latitude: userLoc.latitude,
      longitude: userLoc.longitude,
    );
  }
}
