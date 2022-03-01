import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/users_record.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/services/firebase.dart';
import 'package:tapkat/utilities/auth_util.dart';
import 'package:tapkat/utilities/upload_media.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final authService = AuthService();
  final userRepo = UserRepository();

  User? currentUser;
  UserModel? currentUserModel;
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      emit(AuthLoading());
      print('new event: $event');
      if (event is InitializeAuth) {
        emit(AuthInitialized(authService.tapkatFirebaseUserStream()));
      }

      if (event is GetCurrentuser) {
        emit(GetCurrentUsersuccess(
            authService.currentUser!.user!, authService.currentUserModel));
      }

      if (event is SignUp) {
        final user = await authService.createAccountWithEmail(
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

          authService.currentUser = TapkatFirebaseUser(user);
          currentUser = user;

          final userModel = await userRepo.getUser(user.uid);
          if (userModel != null) {
            currentUserModel = userModel;
            authService.currentUserModel = userModel;
          }

          emit(ShowSignUpPhoto());
        } else {
          emit(AuthError('Error signing up'));
        }
      }

      try {
        if (event is SignInFacebook) {
          final user = await authService.signInWithFacebook();
          if (user != null) emit(AuthSignedIn(user));
        }

        if (event is SignInGoogle) {
          final user = await authService.signInWithGoogle();
          if (user != null) {
            emit(AuthSignedIn(user));
            final userModel = await userRepo.getUser(user.uid);
            if (userModel != null) {
              currentUserModel = userModel;
              authService.currentUserModel = userModel;
            }
          }
        }

        if (event is SignInApple) {
          final user = await authService.signInWithApple();
          if (user != null) emit(AuthSignedIn(user));
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
                UsersRecord.collection.doc(authService.currentUser!.user!.uid);

            await userRef.update(usersUpdateData);

            emit(AuthSignedIn(authService.currentUser!.user!));
          } else {
            emit(AuthError('error saving user photo'));
          }
        }
      } catch (e) {
        emit(AuthError('auth error: ${e.toString()}'));
      }

      if (event is SkipSignUpPhoto) {
        print('asd');
        print('user: ${authService.currentUser!.user!.uid}');
        if (authService.currentUser != null) {
          // emit(AuthSignedIn(authService.currentUser!.user!));
          emit(ShowSignUpSocialMedia());
        }
      }

      if (event is SkipSignUpSocialMedia) {
        print('haha');
        if (authService.currentUser != null) {
          emit(AuthSignedIn(authService.currentUser!.user!));
          // emit(ShowSignUpSocialMedia());
        }
      }

      if (event is SignInWithEmail) {
        final user = await authService.signInWithEmail(
            event.context, event.email, event.password);
        if (user != null) {
          print('success sign in');
          currentUser = user;
          authService.currentUser = TapkatFirebaseUser(user);
          final userModel = await userRepo.getUser(user.uid);
          if (userModel != null) {
            currentUserModel = userModel;
            authService.currentUserModel = userModel;
          }
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
