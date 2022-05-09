part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class InitializeAuth extends AuthEvent {}

class SignInAsGuest extends AuthEvent {}

class ResendEmail extends AuthEvent {}

class SignInWithEmail extends AuthEvent {
  final String email;
  final String password;
  final BuildContext context;

  SignInWithEmail({
    required this.context,
    required this.email,
    required this.password,
  });
}

class UpdatePushAlert extends AuthEvent {
  final bool enable;

  UpdatePushAlert(this.enable);
}

class SignInGoogle extends AuthEvent {}

class SignInFacebook extends AuthEvent {}

class SignInApple extends AuthEvent {}

class SignOut extends AuthEvent {
  final BuildContext context;

  SignOut(this.context);
}

class SignInWithFB extends AuthEvent {}

class SignInWithGoogle extends AuthEvent {}

class SignInWithApple extends AuthEvent {}

class SignInWithMobileNumber extends AuthEvent {
  final String phoneNumber;
  final int? forceResendingToken;

  SignInWithMobileNumber(this.phoneNumber, this.forceResendingToken);
}

class PhoneAuthError extends AuthEvent {
  final String? message;

  PhoneAuthError(this.message);
}

class PhoneOtpSent extends AuthEvent {
  final String verificationId;
  final int? forceResendingToken;

  PhoneOtpSent(this.verificationId, this.forceResendingToken);
}

class VerifyPhoneOtp extends AuthEvent {
  final String verificationId;
  final String otpCode;

  VerifyPhoneOtp(this.verificationId, this.otpCode);
}

class SignUp extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final PlaceDetails location;
  final BuildContext context;
  final String mobileNumber;

  SignUp({
    required this.email,
    required this.password,
    required this.username,
    required this.location,
    required this.context,
    required this.mobileNumber,
  });
}

class SaveUserPhoto extends AuthEvent {
  final BuildContext context;
  final SelectedMedia selectedMedia;

  SaveUserPhoto(this.context, this.selectedMedia);
}

class SkipSignUpPhoto extends AuthEvent {}

class SkipSignUpSocialMedia extends AuthEvent {}

class SignUpPhotoSuccess extends AuthEvent {}

class GetCurrentuser extends AuthEvent {}
