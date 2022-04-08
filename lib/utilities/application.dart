library application;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/user.dart';

User? currentUser;
UserModel? currentUserModel;

bool chatOpened = false;
