library application;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/user.dart';

User? currentUser;
UserModel? currentUserModel;
String? deviceId;

bool chatOpened = false;
LocationModel? currentUserLocation;

List<ChatMessageModel> unreadBarterMessages = [];
