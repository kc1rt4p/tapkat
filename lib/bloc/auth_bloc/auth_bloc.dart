import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:tapkat/schemas/users_record.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/services/firebase.dart';
import 'package:tapkat/utilities/auth_util.dart';
import 'package:tapkat/utilities/upload_media.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _authService = AuthService();
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      emit(AuthLoading());
      print('new event: $event');
      if (event is InitializeAuth) {
        emit(AuthInitialized(_authService.tapkatFirebaseUserStream()));
      }

      if (event is GetCurrentuser) {
        emit(GetCurrentUsersuccess(_authService.currentUser!.user!));
      }

      if (event is SignUp) {
        final user = await _authService.createAccountWithEmail(
          event.context,
          event.email,
          event.password,
        );

        if (user != null) {
          final usersCreateData = createUsersRecordData(
            email: event.email,
            displayName: event.username,
            phoneNumber: event.mobileNumber,
            location: LatLng(0, 0),
          );

          await UsersRecord.collection.doc(user.uid).update(usersCreateData);

          _authService.currentUser = TapkatFirebaseUser(user);

          emit(ShowSignUpPhoto());
        } else {
          emit(AuthError('Error signing up'));
        }
      }

      if (event is SaveUserPhoto) {
        final downloadUrl = await uploadData(
            event.selectedMedia.storagePath, event.selectedMedia.bytes);

        ScaffoldMessenger.of(event.context).hideCurrentSnackBar();

        if (downloadUrl != null) {
          final usersUpdateData = createUsersRecordData(
            photoUrl: downloadUrl,
          );

          final userRef =
              UsersRecord.collection.doc(_authService.currentUser!.user!.uid);

          await userRef.update(usersUpdateData);

          emit(AuthSignedIn(_authService.currentUser!.user!));
        } else {
          emit(AuthError('error saving user photo'));
        }
      }

      if (event is SkipSignUpPhoto && event is SignUpPhotoSuccess) {
        print('user: ${_authService.currentUser!.user!.uid}');
        if (_authService.currentUser != null) {
          emit(AuthSignedIn(_authService.currentUser!.user!));
        }
      }

      if (event is SignInWithEmail) {
        print('signing in with email');
        final user = await _authService.signInWithEmail(
            event.context, event.email, event.password);
        print(user.toString());
        if (user != null) {
          print('success sign in');
          emit(AuthSignedIn(user));
        } else {
          emit(AuthError(''));
        }
      }

      if (event is SignOut) {
        signOut();
        emit(AuthSignedOut());
      }
    });
  }
}
