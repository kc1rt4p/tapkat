library application;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/services/navigator_service.dart';

User? currentUser;
UserModel? currentUserModel;
String? deviceId;
String? deviceName;

bool chatOpened = false;
LocationModel? currentUserLocation;

List<ChatMessageModel> unreadBarterMessages = [];

var currentContext = NavigatorService.instance.navigatorKey.currentContext!;

int? lastEmailResendVerification;

String? currentCountry;

String? currentScreen;
