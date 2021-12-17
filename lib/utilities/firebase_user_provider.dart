import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class TapkatFirebaseUser {
  TapkatFirebaseUser(this.user);
  final User user;
  bool get loggedIn => user != null;
}

TapkatFirebaseUser? currentUser;
bool get loggedIn => currentUser?.loggedIn ?? false;
Stream<TapkatFirebaseUser> tapkatFirebaseUserStream() => FirebaseAuth.instance
    .authStateChanges()
    .debounce((user) => user == null && !loggedIn
        ? TimerStream(true, const Duration(seconds: 1))
        : Stream.value(user))
    .map<TapkatFirebaseUser>((user) => currentUser = TapkatFirebaseUser(user!));
