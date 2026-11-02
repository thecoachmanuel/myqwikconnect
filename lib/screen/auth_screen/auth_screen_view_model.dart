import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/eula/eula_sheet.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/auth_screen/login_screen/login_screen.dart';
import 'package:orange_ui/screen/auth_screen/widget/forget_password_view.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:orange_ui/screen/restart_app/restart_app.dart';
import 'package:orange_ui/service/firebase_notification_manager.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:stacked/stacked.dart';

class AuthScreenViewModel extends BaseViewModel {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  int pageIndex = 0;
  final GoogleSignIn signIn = GoogleSignIn.instance;

  PageController pageController = PageController();

  void init(int index) {
    bool isLogin = SessionManager.instance.getBool(key: SessionKeys.isLogin);
    final user = SessionManager.instance.getUser();
    if (isLogin && user != null && (user.id ?? 0) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/dashboard');
      });
      return;
    }
    FirebaseNotificationManager.shared;
    pageController = PageController(initialPage: index);
    openEULASheet();
  }

  void openEULASheet() {
    bool isNotOpen = SessionManager.instance.getBool(key: SessionKeys.eULA);
    if (AppPlatform.isIOS && !isNotOpen) {
      Future.delayed(
        const Duration(milliseconds: 250),
        () {
          Get.bottomSheet(const EulaSheet(),
              isScrollControlled: true, enableDrag: false);
        },
      );
    }
  }

  void onLoginTap(int index) {
    pageIndex = index;
    notifyListeners();
    Get.to(() => LoginScreen(index: index, viewModel: this));
  }

  void onGoogleTap() async {
    CommonUI.lottieLoader();
    UserCredential? credential;
    try {
      credential = await signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Firebase Auth Error (Google): ${e.code} - ${e.message}');
      CommonUI.snackBar(message: _getFirebaseErrorMessage(e));
      return;
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Google Sign-In Error: $e');
      final err = e.toString().toLowerCase();
      if (!err.contains('cancel') && !err.contains('abort') && !err.contains('closed')) {
        CommonUI.snackBar(message: 'Google Sign-In failed: ${e.toString().replaceAll('Exception:', '').trim()}');
      }
      return;
    }

    if (credential?.user == null) {
      if (Get.isDialogOpen == true) Get.back();
      return;
    }
    registration(
      email: credential?.user?.email ?? '',
      loginType: LoginType.google.value,
      fullName: credential?.user?.displayName ??
          credential?.user?.email?.split('@')[0] ??
          'User',
      firebaseUid: credential?.user?.uid,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      signIn.initialize();
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser =
          await signIn.authenticate(scopeHint: ['email']);

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }

  void registration(
      {bool isRegistration = false,
      required String email,
      required String fullName,
      required int loginType,
      String? password,
      String? firebaseUid,
      Function(UserData? userData)? onCompletion}) {
    FirebaseNotificationManager.shared.getNotificationToken(
      (token) {
        ApiProvider()
            .registration(
                email: email,
                fullName: fullName,
                deviceToken: token,
                loginType: loginType,
                password: password,
                firebaseUid: firebaseUid ?? FirebaseAuth.instance.currentUser?.uid)
            .then((value) {
          if (value.status == true) {
            if (Get.isDialogOpen == true) Get.back();
            if (isRegistration && onCompletion != null) {
              onCompletion.call(value.data);
            } else {
              SessionManager.instance
                  .setBool(key: SessionKeys.isLogin, value: true);
              if (value.data != null) {
                SessionManager.instance.setUser(value.data);
              }
              final bool isNew = isRegistration || (value.isNew == true) || (value.data?.isProfileComplete == 0);
              navigateScreen(userData: value.data, isRegistration: isNew);
            }
            notifyListeners();

            if (value.data?.appLanguage != null &&
                value.data?.appLanguage !=
                    SessionManager.instance
                        .getString(key: SessionKeys.languageCode)) {
              ApiProvider()
                  .updateProfile(appLanguage: value.data?.appLanguage)
                  .then((res) {
                SessionManager.instance.setString(
                    key: SessionKeys.languageCode,
                    value: res.data?.appLanguage ?? AppPlatform.languageCode);
                RestartWidget.restartApp(Get.context!);
              });
            }
          } else {
            if (Get.isDialogOpen == true) Get.back();
            CommonUI.snackBar(message: value.message ?? 'Authentication failed');
          }
        }).catchError((e) {
          if (Get.isDialogOpen == true) Get.back();
          CommonUI.snackBar(message: 'Authentication failed. Please check connection.');
        });
      },
    );
  }

  void onAppleTap() async {
    CommonUI.lottieLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
      log('EMAIL : ${credential?.user?.email} FULLNAME : ${credential?.user?.displayName ?? credential?.user?.email?.split('@')[0]}');
    } on FirebaseAuthException catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Firebase Auth Error (Apple): ${e.code} - ${e.message}');
      CommonUI.snackBar(message: _getFirebaseErrorMessage(e));
      return;
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Apple Sign-In Error: $e');
      final err = e.toString().toLowerCase();
      if (!err.contains('cancel') && !err.contains('canceled') && !err.contains('1001')) {
        CommonUI.snackBar(message: 'Apple Sign-In failed. Please try again.');
      }
      return;
    }
    if (credential?.user == null) {
      if (Get.isDialogOpen == true) Get.back();
      return;
    }
    registration(
      email: credential?.user?.email ?? '',
      loginType: LoginType.apple.value,
      fullName: credential?.user?.displayName ??
          credential?.user?.email?.split('@')[0] ??
          'User',
      firebaseUid: credential?.user?.uid,
    );
  }

  Future<UserCredential?> signInWithApple() async {
    if (kIsWeb) {
      OAuthProvider appleProvider = OAuthProvider("apple.com");
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      return await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple.
      final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode);

      return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    }
  }

  Future<void> navigateScreen({UserData? userData, bool isRegistration = false}) async {
    if (userData == null) {
      Get.offAllNamed('/auth');
      return;
    }

    if (isRegistration) {
      final controller = Get.isRegistered<CreateProfileScreenViewModel>()
          ? Get.find<CreateProfileScreenViewModel>()
          : Get.put(CreateProfileScreenViewModel());
      controller.init(userData);
      Get.offAll(() => CreateProfileScreen(model: controller));
      return;
    }

    if (_isBasicProfileIncomplete(userData)) {
      final controller = Get.isRegistered<CreateProfileScreenViewModel>()
          ? Get.find<CreateProfileScreenViewModel>()
          : Get.put(CreateProfileScreenViewModel());
      controller.init(userData);
      Get.offAll(() => CreateProfileScreen(model: controller));
      return;
    }

    Get.offAllNamed('/dashboard');
  }

// Helper functions for clarity
  bool _isBasicProfileIncomplete(UserData user) {
    return (user.fullname?.trim().isEmpty ?? true) ||
        (user.bio?.trim().isEmpty ?? true) ||
        (user.country?.trim().isEmpty ?? true) ||
        (user.state?.trim().isEmpty ?? true) ||
        (user.city?.trim().isEmpty ?? true) ||
        (user.images == null || user.images!.isEmpty);
  }

  Future<void> onContinueTap() async {
    if (pageIndex == 1) {
      if (fullNameController.text.trim().isEmpty) {
        return CommonUI.snackBar(message: S.current.enterFullName);
      }
    }
    if (emailController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterEmail);
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      return CommonUI.snackBar(message: 'Please enter a valid email address');
    }
    if (passwordController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterPassword);
    }
    if (pageIndex == 1) {
      if (passwordController.text.trim().length < 6) {
        return CommonUI.snackBar(message: 'Password must be at least 6 characters');
      }
      if (confirmPasswordController.text.trim().isEmpty) {
        return CommonUI.snackBar(message: S.current.enterConfirmPassword);
      }
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        return CommonUI.snackBar(message: S.current.passwordMismatch);
      }
    }

    CommonUI.lottieLoader();

    final inputEmail = emailController.text.trim();
    final inputPassword = passwordController.text.trim();
    final inputFullName = fullNameController.text.trim();

    if (pageIndex == 0) {
      // ===== LOGIN FLOW =====
      String? firebaseUid;
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: inputEmail,
          password: inputPassword,
        );
        firebaseUid = cred.user?.uid;
      } catch (e) {
        log('Firebase login notice: $e');
      }

      // Authenticate with backend database
      FirebaseNotificationManager.shared.getNotificationToken((token) async {
        try {
          final loginRes = await ApiProvider().fakeUserLogin(
            email: inputEmail,
            password: inputPassword,
            deviceToken: token,
          );

          if (Get.isDialogOpen == true) Get.back();

          if (loginRes.status == true && loginRes.data != null) {
            SessionManager.instance.setBool(key: SessionKeys.isLogin, value: true);
            SessionManager.instance.setString(key: SessionKeys.password, value: inputPassword);
            SessionManager.instance.setUser(loginRes.data);
            navigateScreen(userData: loginRes.data, isRegistration: false);
          } else {
            // If backend user doesn't exist yet but Firebase authenticated: auto-register on backend
            if (firebaseUid != null && firebaseUid.isNotEmpty) {
              registration(
                email: inputEmail,
                fullName: inputFullName.isNotEmpty ? inputFullName : inputEmail.split('@')[0],
                loginType: LoginType.email.value,
                password: inputPassword,
                firebaseUid: firebaseUid,
                isRegistration: false,
              );
            } else {
              CommonUI.snackBar(
                message: loginRes.message ?? 'Invalid email or password. Please try again.',
              );
            }
          }
        } catch (e) {
          if (Get.isDialogOpen == true) Get.back();
          CommonUI.snackBar(message: 'Login failed. Please check connection.');
        }
      });
    } else {
      // ===== SIGN UP FLOW =====
      String? firebaseUid;
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: inputEmail,
          password: inputPassword,
        );
        try {
          await cred.user?.updateDisplayName(inputFullName);
        } catch (_) {}
        firebaseUid = cred.user?.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          if (Get.isDialogOpen == true) Get.back();
          CommonUI.snackBar(message: 'This email is already registered. Please log in.');
          pageIndex = 0;
          pageController.animateToPage(0,
              duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
          notifyListeners();
          return;
        }
        log('Firebase register notice: ${e.code} - ${e.message}');
      } catch (e) {
        log('Firebase register error: $e');
      }

      // Register with backend and immediately launch the onboarding flow
      FirebaseNotificationManager.shared.getNotificationToken((token) async {
        try {
          final regRes = await ApiProvider().registration(
            email: inputEmail,
            fullName: inputFullName,
            password: inputPassword,
            deviceToken: token,
            loginType: LoginType.email.value,
            firebaseUid: firebaseUid,
          );

          if (Get.isDialogOpen == true) Get.back();

          if (regRes.status == true && regRes.data != null) {
            SessionManager.instance.setBool(key: SessionKeys.isLogin, value: true);
            SessionManager.instance.setString(key: SessionKeys.password, value: inputPassword);
            SessionManager.instance.setUser(regRes.data);
            navigateScreen(userData: regRes.data, isRegistration: true);
          } else {
            CommonUI.snackBar(message: regRes.message ?? 'Registration failed. Please try again.');
          }
        } catch (e) {
          if (Get.isDialogOpen == true) Get.back();
          CommonUI.snackBar(message: 'Registration failed. Please try again.');
        }
      });
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Firebase Auth Error (Login): ${e.code} - ${e.message}');
      CommonUI.snackBar(message: _getFirebaseErrorMessage(e));
      return null;
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Login unexpected error: $e');
      CommonUI.snackBar(
          message: 'Sign-in failed. Please check your credentials and try again.');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Firebase Auth Error (Register): ${e.code} - ${e.message}');
      CommonUI.snackBar(message: _getFirebaseErrorMessage(e));
      return null;
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('Register unexpected error: $e');
      CommonUI.snackBar(
          message: 'Registration failed. Please check your network and try again.');
      return null;
    }
  }

  void onForgotPasswordTap() {
    Get.to(() => ForgetPasswordView(viewModel: this));
  }

  void onForgetPassword() async {
    if (emailController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterEmail);
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      return CommonUI.snackBar(message: 'Please enter a valid email address');
    }
    CommonUI.lottieLoader();
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      if (Get.isDialogOpen == true) Get.back();
      Get.back();
      CommonUI.snackBar(
          message: S.current.aResetPasswordLinkHasBeenSentToYourEmail);
    } on FirebaseAuthException catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      CommonUI.snackBar(message: _getFirebaseErrorMessage(e));
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      CommonUI.snackBar(message: 'Failed to send reset link. Please try again.');
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    final msg = (e.message ?? '').toLowerCase();
    final code = e.code.toLowerCase();

    if (code == 'invalid-action-code' ||
        msg.contains('action is invalid') ||
        msg.contains('requested action is invalid')) {
      return 'Google Sign-in setup required: in Firebase Console > Authentication > Sign-in method, ensure Google provider is enabled with a Project Support Email selected, and "myqwikconnect-web.vercel.app" is listed in Authorized Domains.';
    }

    switch (code) {
      case 'invalid-credential':
      case 'invalid_login_credentials':
      case 'wrong-password':
        return 'Incorrect email or password. Please verify your credentials or register an account.';
      case 'user-not-found':
        return 'No account found with this email. Please switch to the Register tab to create an account.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please switch to Log In.';
      case 'weak-password':
        return 'The password provided is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact customer support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Access is temporarily disabled. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled in Firebase Console. Please enable it in Firebase Console > Authentication > Sign-in method.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Console. Please add your web domain to Firebase Console > Authentication > Settings > Authorized domains.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection and try again.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed before completing.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email using a different sign-in provider.';
      default:
        if (e.message != null && e.message!.isNotEmpty) {
          return e.message!;
        }
        return 'Authentication failed (${e.code}). Please try again.';
    }
  }
}

enum LoginType {
  google(1),
  apple(2),
  facebook(3),
  email(4);

  final int value;

  const LoginType(this.value);
}
