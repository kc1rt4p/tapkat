import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/services/tapkat_encryption.dart';

class AuthRepository {
  final _apiService = ApiService();
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<String> testHeader({
    required String userid,
    required String deviceid,
    required String time,
  }) async {
    final response = await _apiService.get(
      url: 'apitest',
      headers: {
        'userid': userid,
        'deviceid': deviceid,
        'time': time,
        'authorization': TapKatEncryption.encryptMsg(userid + deviceid + time),
      },
    );

    return response.data['message'] as String;
  }
}
