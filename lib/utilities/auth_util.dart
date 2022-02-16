import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/schemas/users_record.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/utilities/firebase_user_provider.dart';

/// Tries to sign in or create an account using Firebase Auth.
/// Returns the User object if sign in was successful.

Future signOut() => FirebaseAuth.instance.signOut();

Future resetPassword(
    {required String email, required BuildContext context}) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
    return null;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Password reset email sent!')),
  );
}

Future sendEmailVerification() async =>
    currentUser?.user.sendEmailVerification();

String get currentUserEmail =>
    currentUserDocument?.email ?? currentUser?.user.email ?? '';

String get currentUserUid =>
    currentUserDocument?.uid ?? currentUser?.user.uid ?? '';

String get currentUserDisplayName =>
    currentUserDocument?.displayName ?? currentUser?.user.displayName ?? '';

String get currentUserPhoto =>
    currentUserDocument?.photoUrl ?? currentUser?.user.photoURL ?? '';

String get currentPhoneNumber =>
    currentUserDocument?.phoneNumber ?? currentUser?.user.phoneNumber ?? '';

bool get currentUserEmailVerified => currentUser?.user.emailVerified ?? false;

// Set when using phone verification (after phone number is provided).
String? _phoneAuthVerificationCode;
// Set when using phone sign in in web mode (ignored otherwise).
ConfirmationResult? _webPhoneAuthConfirmationResult;

Future beginPhoneAuth({
  required BuildContext context,
  required String phoneNumber,
  required VoidCallback onCodeSent,
}) async {
  if (kIsWeb) {
    _webPhoneAuthConfirmationResult =
        await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
    onCodeSent();
    return;
  }
  // If you'd like auto-verification, without the user having to enter the SMS
  // code manually. Follow these instructions:
  // * For Android: https://firebase.google.com/docs/auth/android/phone-auth?authuser=0#enable-app-verification (SafetyNet set up)
  // * For iOS: https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0#start-receiving-silent-notifications
  // * Finally modify verificationCompleted below as instructed.
  await FirebaseAuth.instance.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    timeout: Duration(seconds: 5),
    verificationCompleted: (phoneAuthCredential) async {
      await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
      // If you've implemented auto-verification, navigate to home page or
      // onboarding page here manually. Uncomment the lines below and replace
      // DestinationPage() with the desired widget.
      // await Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (_) => DestinationPage()),
      // );
    },
    verificationFailed: (exception) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error with phone verification: ${exception.message}'),
      ));
    },
    codeSent: (verificationId, _) {
      _phoneAuthVerificationCode = verificationId;
      onCodeSent();
    },
    codeAutoRetrievalTimeout: (_) {},
  );
}

Future verifySmsCode({
  required BuildContext context,
  required String smsCode,
}) async {
  if (kIsWeb) {
    return AuthService().signInOrCreateAccount(
        () => _webPhoneAuthConfirmationResult!.confirm(smsCode));
  } else {
    final authCredential = PhoneAuthProvider.credential(
        verificationId: _phoneAuthVerificationCode!, smsCode: smsCode);
    return AuthService().signInOrCreateAccount(
      () => FirebaseAuth.instance.signInWithCredential(authCredential),
    );
  }
}

DocumentReference? get currentUserReference => currentUser!.user != null
    ? UsersRecord.collection.doc(currentUser!.user.uid)
    : null;

UsersRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap((uid) => queryUsersRecord(
        queryBuilder: (user) => user.where('uid', isEqualTo: uid),
        singleRecord: true))
    .map((users) => currentUserDocument = users.isNotEmpty ? users.first : null)
    .asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => child,
      );
}
