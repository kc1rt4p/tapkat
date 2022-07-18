import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/users_record.dart';
import 'package:tapkat/utilities/helper.dart';
import 'package:tapkat/utilities/application.dart' as application;

class TapkatFirebaseUser {
  TapkatFirebaseUser(this.user);
  final User? user;
  bool get loggedIn => user != null;
}

class AuthService {
  final _googleSignIn = GoogleSignIn();
  UserModel? currentUserModel;
  TapkatFirebaseUser? currentUser;
  bool get loggedIn => currentUser?.loggedIn ?? false;
  final _userRepo = UserRepository();
  Stream<TapkatFirebaseUser> tapkatFirebaseUserStream() => FirebaseAuth.instance
      .authStateChanges()
      .debounce((user) => user == null && !loggedIn
          ? TimerStream(true, const Duration(seconds: 1))
          : Stream.value(user))
      .map<TapkatFirebaseUser>(
          (user) => currentUser = TapkatFirebaseUser(user));

  Future<User?> signInOrCreateAccount(
      Future<UserCredential?> Function() signInFunc,
      {bool registering = false}) async {
    final userCredential = await signInFunc();
    if (userCredential != null) {
      if (!userCredential.user!.emailVerified) {
        print('0----> SENDING EMAIL VERIFICATION!!');
        try {
          FirebaseAuth.instance.currentUser!.sendEmailVerification();
        } catch (e) {
          print('0-> ${e.toString()}');
        }
      }
      await maybeCreateUser(userCredential.user!);
      return userCredential.user!;
    }

    return null;
  }

  Future<dynamic> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: application.currentUser!.email!, password: currentPassword);
    } on FirebaseAuthException catch (e) {
      return e.message;
    }

    try {
      FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  Future<User?> signInAnonymously() async {
    final signInFunc = () => FirebaseAuth.instance.signInAnonymously();
    return signInOrCreateAccount(signInFunc);
  }

  Future<void> resendEmail() async {
    await FirebaseAuth.instance.currentUser!.sendEmailVerification();
    application.lastEmailResendVerification =
        DateTime.now().millisecondsSinceEpoch;
  }

  Future maybeCreateUser(User user) async {
    final userRecord = UsersRecord.collection.doc(user.uid);
    final userExists = await userRecord.get().then((u) => u.exists);
    if (userExists) {
      return;
    }

    final userData = createUsersRecordData(
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      createdTime: getCurrentTimestamp,
      updatedTime: getCurrentTimestamp,
    );

    await userRecord.set(userData);
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> appleSignIn() async {
    if (kIsWeb) {
      final provider = OAuthProvider("apple.com")
        ..addScope('email')
        ..addScope('name');

      // Sign in the user with Firebase.
      return await FirebaseAuth.instance.signInWithPopup(provider);
    }
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Future<User?> signInWithApple() => signInOrCreateAccount(appleSignIn);

  Future<User?> signInWithEmail(
      BuildContext context, String email, String password) async {
    final signInFunc = () => FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);
    return signInOrCreateAccount(signInFunc);
  }

  Future<User?> createAccountWithEmail(
      BuildContext context, String email, String password) async {
    final createAccountFunc = () => FirebaseAuth.instance
        .createUserWithEmailAndPassword(
            email: email.trim(), password: password);
    return signInOrCreateAccount(createAccountFunc, registering: true);
  }

  Future<User?> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login(
      permissions: [
        'email',
        'public_profile',
        'user_friends',
      ],
      loginBehavior: LoginBehavior.nativeWithFallback,
    );

    if (loginResult.status != LoginStatus.success) return null;

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

    // Once signed in, return the UserCredential
    return signInOrCreateAccount(() =>
        FirebaseAuth.instance.signInWithCredential(facebookAuthCredential));
  }

  // Future<UserCredential> signInWithGoogle() async {
  //   // Trigger the authentication flow
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  //   // Obtain the auth details from the request
  //   final GoogleSignInAuthentication? googleAuth =
  //       await googleUser?.authentication;

  //   // Create a new credential
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth?.accessToken,
  //     idToken: googleAuth?.idToken,
  //   );

  //   // Once signed in, return the UserCredential
  //   return await FirebaseAuth.instance.signInWithCredential(credential);
  // }

  Future<User?> signInWithGoogle() async {
    final signInFunc = () async {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider
            .addScope('https://www.googleapis.com/auth/contacts.readonly');
        // Once signed in, return the UserCredential
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      }

      await signOutWithGoogle().catchError((_) => null);
      final auth = await (await _googleSignIn.signIn())?.authentication;
      if (auth == null) {
        return null;
      }
      final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken, accessToken: auth.accessToken);
      return FirebaseAuth.instance.signInWithCredential(credential);
    };
    return signInOrCreateAccount(signInFunc);
  }

  Future signOutWithGoogle() => _googleSignIn.signOut();
}
