import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/users_record.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/services/firebase.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/utilities/auth_util.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final authService = AuthService();
  final userRepo = UserRepository();

  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      emit(AuthLoading());
      if (event is InitializeAuth) {
        emit(AuthInitialized(authService.tapkatFirebaseUserStream()));
      }

      if (event is GetCurrentuser) {
        final _user = FirebaseAuth.instance.currentUser;
        application.currentUser = _user;
        if (_user != null) {
          application.currentUserModel =
              application.currentUserModel ?? await userRepo.getUser(_user.uid);
        }

        emit(GetCurrentUsersuccess(
            application.currentUser!, application.currentUserModel));
      }

      if (event is ResendEmail) {
        authService.resendEmail();
        emit(ResendEmailSuccess());
      }

      if (event is UpdatePushAlert) {
        final updated = await userRepo.updatePushAlert(event.enable);
        final updatedToken = await userRepo.updateUserFCMToken();
        if (updated && updatedToken) {
          application.currentUserModel =
              await userRepo.getUser(application.currentUser!.uid);
          emit(UpdatePushAlertSuccess());
        }
      }

      if (event is SignUp) {
        try {
          final user = await authService.createAccountWithEmail(
            event.context,
            event.email,
            event.password,
          );

          if (user != null) {
            application.currentUser = user;
            final _location = event.location;

            final updateUser = UpdateUserModel(
              userid: user.uid,
              email: event.email,
              display_name: event.username,
              phone_number: event.mobileNumber,
              location: LocationModel(
                latitude: event.location.geometry!.location.lat,
                longitude: event.location.geometry!.location.lng,
              ),
              address: _location.addressComponents[0] != null
                  ? _location.addressComponents[0]!.longName
                  : null,
              city: _location.addressComponents[1] != null
                  ? _location.addressComponents[1]!.longName
                  : null,
              country: _location.addressComponents.last != null
                  ? _location.addressComponents.last!.longName
                  : null,
            );

            await UsersRecord.collection
                .doc(user.uid)
                .update(updateUser.toJson());

            final userModel = await userRepo.getUser(user.uid);
            if (userModel != null) {
              application.currentUserModel = userModel;
              _loadUserLocation();
            }

            emit(ShowSignUpPhoto());
          }
        } on FirebaseAuthException catch (e) {
          emit(AuthError(e.message ?? e.toString()));
        }
      }

      try {
        if (event is SignInFacebook) {
          final user = await authService.signInWithFacebook();
          if (user != null) {
            application.currentUserModel = await userRepo.getUser(user.uid);

            if (application.currentUserModel != null) {
              _loadUserLocation();
              emit(AuthSignedIn(user));
            }
          }
        }

        if (event is SignInGoogle) {
          final user = await authService.signInWithGoogle();
          if (user != null) {
            application.currentUser = user;
            final userModel = await userRepo.getUser(user.uid);
            if (userModel != null) {
              application.currentUserModel = userModel;
              _loadUserLocation();
            }

            emit(AuthSignedIn(user));
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
            final userRef =
                UsersRecord.collection.doc(authService.currentUser!.user!.uid);

            await userRef.update({"photo_url": downloadUrl});

            emit(SaveUserPhotoSuccess());

            // emit(AuthSignedIn(authService.currentUser!.user!));
          } else {
            emit(AuthError('error saving user photo'));
          }
        }
      } catch (e) {
        emit(AuthError('auth error: ${e.toString()}'));
      }

      if (event is SkipSignUpPhoto) {
        if (authService.currentUser != null) {
          emit(AuthSignedIn(authService.currentUser!.user!));
          // emit(ShowSignUpSocialMedia());
        }
      }

      if (event is SkipSignUpSocialMedia) {
        if (authService.currentUser != null) {
          emit(AuthSignedIn(authService.currentUser!.user!));
          // emit(ShowSignUpSocialMedia());
        }
      }

      if (event is SignInWithEmail) {
        try {
          signOut();
          final user = await authService.signInWithEmail(
              event.context, event.email, event.password);
          if (user != null) {
            print('success sign in');
            application.currentUser = user;
            authService.currentUser = TapkatFirebaseUser(user);
            final userModel = await userRepo.getUser(user.uid);
            if (userModel != null) {
              application.currentUserModel = userModel;

              _loadUserLocation();
            }
            emit(AuthSignedIn(user));
          }
        } on FirebaseAuthException catch (e) {
          emit(AuthError(e.message ?? e.toString()));
        }
      }

      if (event is SignOut) {
        signOut();
        emit(AuthSignedOut());
      }
    });
  }
}

_loadUserLocation() async {
  if (await Permission.location.isDenied &&
      !(await geoLocator.GeolocatorPlatform.instance
          .isLocationServiceEnabled())) {
    application.currentUserLocation = application.currentUserModel!.location!;
  } else {
    final userLoc = await geoLocator.Geolocator.getCurrentPosition();
    application.currentUserLocation = LocationModel(
      latitude: userLoc.latitude,
      longitude: userLoc.longitude,
    );
  }
}
