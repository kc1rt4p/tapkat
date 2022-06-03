import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/barter/barter_transactions_screen.dart';
import 'package:tapkat/screens/root/home/home_screen.dart';
import 'package:tapkat/screens/root/home/home_screen_new.dart';
import 'package:tapkat/screens/root/profile/profile_screen.dart';
import 'package:tapkat/screens/root/wish_list/wish_list_screen.dart';
import 'package:tapkat/services/dynamic_link.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/utilities/style.dart';

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
  print('__-= BACKGROUND NOTIF: ${message.data}');
}

void handleLinkData(BuildContext currentContext, PendingDynamicLinkData data) {
  final Uri uri = data.link;
  final queryParams = uri.queryParameters;
  print('__-= deep link: $uri');
  if (queryParams.length > 0) {
    print('__-= deep link: $uri');
    final String productid = queryParams["productid"]!;
    if (application.currentUserModel != null) {
      Navigator.push(
        currentContext,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(
            productId: productid,
            ownItem: false,
          ),
        ),
      );
    }
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _screens = [
    HomeScreen(),
    // NewHomeScreen(),
    WishListScreen(),
    BarterTransactionsScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;

  final _rootBloc = RootBloc();
  final _productBloc = ProductBloc();
  late AuthBloc _authBloc;
  late BarterBloc _barterBloc;

  final _currentVerDate = DateTime(2022, 6, 3, 02);

  final _appConfig = new LocalStorage('app_config.json');

  StreamSubscription<ConnectivityResult>? _connectivityStream;
  final _dynamincLinkService = DynamincLinkService();

  @override
  void initState() {
    application.currentScreen = 'Root Screen';
    _barterBloc = BlocProvider.of<BarterBloc>(context);
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());

    super.initState();
    fetchLinkData();
    // testCreateLink();
  }

  // void testCreateLink() async {
  //   final link = await DynamincLinkService().createDynamicLink(data: {
  //     'productid': 'yM2FjnoxtrqEWRmRqiXG',
  //   });
  //   handleLinkData(context, PendingDynamicLinkData(link: link));
  // }

  void fetchLinkData() async {
    // FirebaseDynamicLinks.getInitialLInk does a call to firebase to get us the real link because we have shortened it.
    var link = await FirebaseDynamicLinks.instance.getInitialLink();
    print('_-= $link');
    var message = await FirebaseDynamicLinks.instance
        .getDynamicLink(Uri.parse(_dynamincLinkService.Link));
    print('_-= $message');

    // This link may exist if the app was opened fresh so we'll want to handle it the same way onLink will.
    if (link != null) handleLinkData(context, link);

    // This will handle incoming links if the application is already opened
    try {
      FirebaseDynamicLinks.instance.onLink.listen(
        (data) {
          print('--------- INCOMING!!');
          handleLinkData(context, data);
        },
        onError: (error) => print('======-dynamic-link-error==== __ $error __'),
        onDone: () => print('======-dynamic-link-DONE==== __  __'),
      );
    } catch (e) {
      print('ERROR ON FIREBASE DYNAMIC LINKS::::: ${e.toString()}');
    }
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

    _barterBloc.add(GetUnreadBarterMessages());

    if (!application.chatOpened) {
      await flutterLocalNotificationsPlugin.show(0, message.notification!.title,
          message.notification!.body, platformChannelSpecifics,
          payload: message.data['barterid']);
    }
  }

  Future<void> _firebaseMessageOpened(RemoteMessage message) async {
    final barterId = message.data['barterid'] as String;
    _barterBloc.add(GetUnreadBarterMessages());
    if (barterId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarterScreen(
            barterRecord: BarterRecordModel(barterId: barterId),
            showChatFirst: true,
          ),
        ),
      );
    }
  }

  initNotifications() async {
    final _firebaseMessaging = FirebaseMessaging.instance;
    final _firstLoginDate = await _appConfig.getItem('first_login_date');
    print('_____ FIRST LOGIN DATE:::: $_firstLoginDate');
    // final permissionStatus =
    //     await notif.NotificationPermissions.getNotificationPermissionStatus();
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    List<String> userIds = [];

    if (_firstLoginDate != null) {
      (_firstLoginDate as Map<String, dynamic>).forEach((key, value) {
        if (key != application.currentUser!.uid) {
          print('DELETING $key --0000000000000000000000000000000000000000');
          userIds.add(key);
        }
      });
    }

    if (userIds.isNotEmpty) {
      _rootBloc.add(DeleteRegistrationTokens(userIds));
    }

    if (_firstLoginDate == null) {
      await _appConfig.setItem('first_login_date', {
        application.currentUser!.uid:
            DateTime.now().millisecondsSinceEpoch.toString(),
      });

      _rootBloc.add(UpdateUserToken());
    } else if (_firstLoginDate[application.currentUser!.uid] == null) {
      await _appConfig.setItem('first_login_date', {
        application.currentUser!.uid:
            DateTime.now().millisecondsSinceEpoch.toString(),
      });

      _rootBloc.add(UpdateUserToken());
    }

    // permissionStatus == PermissionStatus.denied ||
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (val) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarterScreen(
            barterRecord: BarterRecordModel(barterId: val),
            showChatFirst: true,
          ),
        ),
      );
    });

    FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessageOpened);

    _connectivityStream =
        Connectivity().onConnectivityChanged.listen((result) async {
      print('__-==CONNECTION CHANGED');
      if (result != ConnectivityResult.none) {
        print('__-==internet is back');
        final message = await FirebaseMessaging.instance.getInitialMessage();

        if (message != null) {
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

          _barterBloc.add(GetUnreadBarterMessages());

          if (!application.chatOpened) {
            await flutterLocalNotificationsPlugin.show(
                0,
                message.notification!.title,
                message.notification!.body,
                platformChannelSpecifics,
                payload: message.data['barterid']);
          }
        }
      } else {
        print('__-==internet is gone');
      }
    });
  }

  @override
  void dispose() {
    // _barterBloc.close();
    // _connectivityStream!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    SizeConfig().init(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => _rootBloc,
          ),
          BlocProvider(
            create: (context) => _productBloc,
          ),
          BlocProvider(
            create: (context) => _barterBloc,
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
                print('ROOT AUTH STATE:::: $state');
                if (state is GetCurrentUsersuccess) {
                  if (application.currentUserLocation == null) {
                    application.currentUserLocation = state.userModel!.location;
                  }

                  initNotifications();
                  _barterBloc.add(GetUnreadBarterMessages());
                }
              },
            ),
            BlocListener(
              bloc: _barterBloc,
              listener: (context, state) {
                if (state is GetUnreadBarterMessagesSuccess) {
                  setState(() {
                    application.unreadBarterMessages = state.messages;
                  });
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
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -3),
                    color: Colors.black54,
                    spreadRadius: 0,
                    blurRadius: 1,
                  ),
                ],
              ),
              padding: EdgeInsets.all(5.0),
              child: FloatingActionButton(
                mini: true,
                heroTag: 'addProductBtn',
                backgroundColor: Color(0xFFBB3F03),
                child: Icon(Icons.add, size: 25.0),
                onPressed: _onAddTapped,
                elevation: 4.0,
              ),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  _onAddTapped() async {
    if (!application.currentUser!.emailVerified ||
        (application.currentUserModel!.signin_method != null &&
            application.currentUserModel!.signin_method == 'EMAIL')) {
      DialogMessage.show(
        context,
        message:
            'Click on the verification link sent to your email address: ${application.currentUser!.email}',
        buttonText: 'Resend',
        firstButtonClicked: () => _authBloc.add(ResendEmail()),
      );
      return;
    }

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
      height: kToolbarHeight - 10,
      color: Color(0xFFEBFBFF),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 0),
              spreadRadius: 0.5,
              blurRadius: 2,
            ),
          ],
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
              showBadge: application.unreadBarterMessages.isNotEmpty,
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
    bool showBadge = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 2 &&
              (!application.currentUser!.emailVerified ||
                  (application.currentUserModel!.signin_method != null &&
                      application.currentUserModel!.signin_method ==
                          'EMAIL'))) {
            DialogMessage.show(
              context,
              message:
                  'Click on the verification link sent to your email address: ${application.currentUser!.email}',
              buttonText: 'Resend',
              firstButtonClicked: () => _authBloc.add(ResendEmail()),
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Color(0xFF94D2BD) : Colors.grey,
                size: isActive ? 30.0 : null,
              ),
              Visibility(
                visible: showBadge,
                child: Positioned(
                  top: 0,
                  right: SizeConfig.screenWidth * 0.06,
                  child: Container(
                    height: 8.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
