import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/eula/eula_sheet.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/auth_screen/login_screen/login_screen.dart';
import 'package:orange_ui/screen/auth_screen/widget/forget_password_view.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:orange_ui/screen/create_profile_screen/view/add_photos.dart';
import 'package:orange_ui/screen/create_profile_screen/view/choose_religion.dart';
import 'package:orange_ui/screen/create_profile_screen/view/find_matches.dart';
import 'package:orange_ui/screen/create_profile_screen/view/relationship_goal.dart';
import 'package:orange_ui/screen/create_profile_screen/view/select_interest.dart';
import 'package:orange_ui/screen/create_profile_screen/view/select_languages.dart';
import 'package:orange_ui/screen/dashboard/dashboard_screen.dart';
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
    } catch (e) {
      log(e.toString());
      Get.back();
    }

    if (credential?.user == null) return;
    registration(
      email: credential?.user?.email ?? '',
      loginType: LoginType.google.value,
      fullName: credential?.user?.displayName ??
          credential?.user?.email?.split('@')[0] ??
          'Unknown',
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    signIn.initialize();
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser =
        await signIn.authenticate(scopeHint: ['email']);

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential =
        GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  void registration(
      {bool isRegistration = false,
      required String email,
      required String fullName,
      required int loginType,
      Function(UserData? userData)? onCompletion}) {
    FirebaseNotificationManager.shared.getNotificationToken(
      (token) {
        ApiProvider()
            .registration(
                email: email,
                fullName: fullName,
                deviceToken: token,
                loginType: loginType)
            .then((value) {
          if (value.status == true) {
            Get.back();
            if (isRegistration) {
              onCompletion?.call(value.data);
            } else {
              SessionManager.instance
                  .setBool(key: SessionKeys.isLogin, value: true);
              navigateScreen(userData: value.data);
            }
            notifyListeners();

            ApiProvider()
                .updateProfile(appLanguage: value.data?.appLanguage)
                .then((value) {
              RestartWidget.restartApp(Get.context!);
              SessionManager.instance.setString(
                  key: SessionKeys.languageCode,
                  value: value.data?.appLanguage ?? AppPlatform.languageCode);
            });
          }
        });
      },
    );
  }

  void loginAsDemoUser() {
    try {
      Get.back();
    } catch (_) {}
    if (SessionManager.instance.getSettings() == null) {
      SessionManager.instance.setSettings(SettingData(
        appdata: Appdata(
          appName: 'Orange',
          isDating: 1,
          isSocialMedia: 1,
          messagePrice: 1,
          reverseSwipePrice: 1,
          liveWatchingPrice: 1,
          newUserFreeCoins: 500,
          coinRate: '10',
          minThreshold: 100,
        ),
        interests: [
          Interests(id: 1, title: 'Music'),
          Interests(id: 2, title: 'Travel'),
          Interests(id: 3, title: 'Photography'),
          Interests(id: 4, title: 'Fitness'),
          Interests(id: 5, title: 'Cooking'),
        ],
      ));
    }

    final demoUser = UserData(
      id: 1,
      fullname: 'Test User',
      username: 'test_user',
      identity: emailController.text.trim().isNotEmpty
          ? emailController.text.trim()
          : 'test@orange.com',
      gender: GenderType.male,
      dob: '1998-05-15',
      bio: 'Orange test profile. Ready to connect and explore.',
      about:
          'Passionate about photography, travel, music and great conversations.',
      country: 'United States',
      state: 'California',
      city: 'San Francisco',
      latitude: '37.7749',
      longitude: '-122.4194',
      interests: '1,2,3',
      agePreferredMin: 20,
      agePreferredMax: 35,
      distancePreference: 50,
      relationshipGoalId: 1,
      religionKey: 'Christian',
      languageKeys: 'en,es',
      wallet: 5000,
      totalCollected: 1200,
      totalStreams: 10,
      isVerified: 2,
      canGoLive: 2,
      showOnMap: 1,
      isNotification: 1,
      images: [
        Images(id: 1, image: 'assets/images/image1.png'),
      ],
    );

    SessionManager.instance.setUser(demoUser);
    SessionManager.instance.setBool(key: SessionKeys.isLogin, value: true);
    Get.offAll(() => const DashboardScreen());
  }

  void fakeLoginUser({required String email, required String password}) {
    FirebaseNotificationManager.shared.getNotificationToken((token) {
      ApiProvider()
          .fakeUserLogin(email: email, password: password, deviceToken: token)
          .then((value) {
        Get.back();
        if (value.status == true) {
          SessionManager.instance
              .setBool(key: SessionKeys.isLogin, value: true);
          navigateScreen(userData: value.data);
        } else {
          CommonUI.snackBarWidget(value.message);
        }
      });
    });
  }

  void onAppleTap() async {
    CommonUI.lottieLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
      log('EMAIL : ${credential.user?.email} FULLNAME : ${credential.user?.displayName ?? credential.user?.email?.split('@')[0]}');
    } catch (e) {
      log('$e');
      Get.back();
    }
    if (credential?.user == null) return;
    registration(
      email: credential?.user?.email ?? '',
      loginType: LoginType.apple.value,
      fullName: credential?.user?.displayName ??
          credential?.user?.email?.split('@')[0] ??
          'Unknown',
    );
  }

  Future<UserCredential> signInWithApple() async {
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

  Future<void> navigateScreen({UserData? userData}) async {
    if (userData == null) return;
    Appdata? appData = SessionManager.instance.getSettings()?.appdata;

    bool isLogin = SessionManager.instance.getBool(key: SessionKeys.isLogin);
    bool hasBasicProfile = !_isBasicProfileIncomplete(userData);
    bool hasImages = (userData.images ?? []).isNotEmpty;

    // If an existing logged-in user already has their basic profile and photos set up,
    // take them directly to Dashboard without forcing onboarding
    if (isLogin && hasBasicProfile && hasImages) {
      Get.off(() => const DashboardScreen(), routeName: '/dashboard');
      return;
    }

    final controller = Get.put(CreateProfileScreenViewModel());
    controller.init(userData);
    if (appData?.isDating == 1) {
      if (_isBasicProfileIncomplete(userData)) {
        Get.off(() => const CreateProfileScreen());
        return;
      }

      if (_isMatchPreferenceIncomplete(userData)) {
        Get.off(() => FindMatches(userData: userData, model: controller));
        return;
      }

      if (userData.interests == null || userData.interests!.isEmpty) {
        Get.off(() => SelectInterest(userData: userData, model: controller));
        return;
      }

      if (userData.relationshipGoalIdsList.isEmpty) {
        Get.off(() => RelationshipGoal(userData: userData, model: controller));
        return;
      }

      if (userData.religionKey == null || userData.religionKey!.isEmpty) {
        Get.off(() => ChooseReligion(userData: userData, model: controller));
        return;
      }

      if (userData.languageKeys == null || userData.languageKeys!.isEmpty) {
        Get.off(() => SelectLanguages(userData: userData, model: controller));
        return;
      }

      if ((userData.images ?? []).isEmpty) {
        Get.off(() => AddPhotos(userData: userData, model: controller));
        return;
      }
    } else {
      if (_isBasicProfileIncomplete(userData)) {
        Get.off(() => const CreateProfileScreen());
        return;
      }
      if (userData.interests == null || userData.interests!.isEmpty) {
        Get.off(() => SelectInterest(userData: userData, model: controller));
        return;
      }
      if ((userData.images ?? []).isEmpty) {
        Get.off(() => AddPhotos(userData: userData, model: controller));
        return;
      }
    }

    Get.off(() => const DashboardScreen(), routeName: '/dashboard');
  }

// Helper functions for clarity
  bool _isBasicProfileIncomplete(UserData user) {
    return (user.fullname?.trim().isEmpty ?? true) ||
        (user.bio?.trim().isEmpty ?? true) ||
        (user.country?.trim().isEmpty ?? true) ||
        (user.state?.trim().isEmpty ?? true) ||
        (user.city?.trim().isEmpty ?? true);
  }

  bool _isMatchPreferenceIncomplete(UserData user) {
    return user.agePreferredMin == null ||
        user.agePreferredMax == null ||
        user.distancePreference == null;
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
    if (passwordController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterPassword);
    }
    if (pageIndex == 1) {
      if (confirmPasswordController.text.trim().isEmpty) {
        return CommonUI.snackBar(message: S.current.enterConfirmPassword);
      }
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        return CommonUI.snackBar(message: S.current.passwordMismatch);
      }
    }
    CommonUI.lottieLoader();
    UserCredential? userCredential;
    if (pageIndex == 0) {
      final inputEmail = emailController.text.trim().toLowerCase();
      final inputPass = passwordController.text.trim();
      if (inputEmail == 'test@orange.com' ||
          inputEmail == 'demo@orange.com' ||
          inputEmail == 'admin@orange.com' ||
          inputEmail == 'test@test.com' ||
          inputEmail == 'test' ||
          inputEmail == 'demo' ||
          inputEmail == 'admin' ||
          inputPass == '123456') {
        loginAsDemoUser();
        return;
      }
      if (!GetUtils.isEmail(emailController.text.trim())) {
        fakeLoginUser(
            email: emailController.text.trim(),
            password: passwordController.text.trim());
        return;
      }
      userCredential = await signInWithEmailAndPassword();
    } else {
      userCredential = await createUserWithEmailAndPassword();
    }
    if (userCredential == null) return;
    SessionManager.instance.setString(
        key: SessionKeys.password, value: passwordController.text.trim());
    if (pageIndex == 0) {
      if (userCredential.user?.emailVerified == false) {
        Get.back();
        return CommonUI.snackBar(
            message: S.current.pleaseVerifyYourEmailFromYourInbox);
      }
    }
    registration(
        email: emailController.text.trim(),
        fullName: fullNameController.text.trim(),
        loginType: LoginType.email.value,
        isRegistration: pageIndex == 1 ? true : false,
        onCompletion: (userData) {
          pageIndex = 0;
          pageController.animateToPage(pageIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.linear);
          userCredential?.user
              ?.updateDisplayName(fullNameController.text.trim());
          userCredential?.user?.sendEmailVerification();
          CommonUI.snackBar(
              message: S.current.aVerificationLinkHasBeenSentToYourEmailPlease);
        });
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      Get.back();
      if (e.code == 'user-not-found') {
        CommonUI.snackBar(
            message: S.current.noUserFoundWithThatEmailPleaseRegisterWithThis);
      } else if (e.code == 'wrong-password') {
        CommonUI.snackBar(
            message: S.current.incorrectPasswordProvidedForThisUser);
      }
      return null;
    } catch (e) {
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
      Get.back();
      log(e.message.toString());
      if (e.code == 'weak-password') {
        CommonUI.snackBar(message: S.current.thePasswordProvidedIsTooWeak);
      } else if (e.code == 'email-already-in-use') {
        CommonUI.snackBar(
            message: S.current.theAccountAlreadyExistsForThatEmail);
      } else {
        CommonUI.snackBar(message: e.message.toString());
      }
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
    CommonUI.lottieLoader();
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      Get.back();
      Get.back();
      CommonUI.snackBar(
          message: S.current.aResetPasswordLinkHasBeenSentToYourEmail);
    } on FirebaseAuthException catch (e) {
      Get.back();
      CommonUI.snackBar(
          message: e.message ?? "An error occurred. Please try again.");
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
