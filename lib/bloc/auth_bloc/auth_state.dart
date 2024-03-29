part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthInitialized extends AuthState {
  final Stream<TapkatFirebaseUser> stream;

  AuthInitialized(this.stream);
}

class SignInGoogleSuccess extends AuthState {
  final User user;

  SignInGoogleSuccess(this.user);
}

class UpdatePushAlertSuccess extends AuthState {}

class ResendEmailSuccess extends AuthState {}

class AuthSignedOut extends AuthState {}

class PhoneVerifiedButNoRecord extends AuthState {}

class PhoneOtpSentSuccess extends AuthState {
  final String verificationId;
  final int? forceResendingToken;

  PhoneOtpSentSuccess(this.verificationId, this.forceResendingToken);
}

class AuthSignedIn extends AuthState {
  final User user;

  AuthSignedIn(this.user);
}

class AuthLoading extends AuthState {}

class InitiatedSignUpScreen extends AuthState {
  final List<LocalizationModel> locList;

  InitiatedSignUpScreen(this.locList);
}

class UpdateOnlineStatusSucces extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

class AuthShowSignUpScreen extends AuthState {}

class ShowSignUpPhoto extends AuthState {}

class ShowSignUpSocialMedia extends AuthState {}

class SaveUserPhotoSuccess extends AuthState {}

class SignUpSuccess extends AuthState {}

class GetCurrentUsersuccess extends AuthState {
  final User user;
  final UserModel? userModel;

  GetCurrentUsersuccess(this.user, this.userModel);
}

class ContinueSignUp extends AuthState {}
