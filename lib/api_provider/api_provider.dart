import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/model/chat_and_live_stream/add_live_stream_history.dart';
import 'package:orange_ui/model/chat_and_live_stream/agora.dart';
import 'package:orange_ui/model/chat_and_live_stream/apply_for_live.dart';
import 'package:orange_ui/model/chat_and_live_stream/fetch_live_stream_history.dart';
import 'package:orange_ui/model/fetch_redeem_request.dart';
import 'package:orange_ui/model/get_diamond_pack.dart';
import 'package:orange_ui/model/get_explore_screen.dart';
import 'package:orange_ui/model/map/fetch_user_coordinate.dart';
import 'package:orange_ui/model/get_package.dart';
import 'package:orange_ui/model/notification/admin_notification.dart';
import 'package:orange_ui/model/notification/user_notification_model.dart';
import 'package:orange_ui/model/place_detail.dart';
import 'package:orange_ui/model/report.dart';
import 'package:orange_ui/model/search/search_user.dart';
import 'package:orange_ui/model/search/search_user_by_id.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/store_file_give_path.dart';
import 'package:orange_ui/model/user/delete_account.dart';
import 'package:orange_ui/model/user/like_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/model/verification.dart';
import 'package:orange_ui/model/wallet/minus_coin_from_wallet.dart';
import 'package:orange_ui/service/firebase_notification_manager.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/const_res.dart';
import 'package:orange_ui/utils/urls.dart';

class ApiProvider {
  Map<String, String> get headers => {
        Urls.apiKeyName: ConstRes.apiKey,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      };
  String get myUserId => SessionManager.instance.getUserID().toString();

  Future<UserModel> registration(
      {required String? email,
      required String? fullName,
      required String? deviceToken,
      required int? loginType,
      String? password,
      String? firebaseUid}) async {
    Map<String, dynamic> map = {};
    map[Urls.fullName] = fullName;
    map[Urls.deviceToken] = deviceToken;
    map[Urls.deviceType] = AppPlatform.isAndroid ? Urls.aOne : Urls.aTwo;
    map[Urls.loginType] = loginType.toString();
    map[Urls.identity] = email;
    if (password != null && password.isNotEmpty) {
      map['password'] = password;
    }
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      map['firebase_uid'] = firebaseUid;
    }
    http.Response response = await http.post(
      Uri.parse(Urls.aRegister),
      headers: headers,
      body: map,
    );
    UserModel user = UserModel.fromJson(jsonDecode(response.body));

    if (user.status == true) {
      if (user.data?.isNotification == 1) {
        FirebaseNotificationManager.shared.subscribeToTopic();
        FirebaseNotificationManager.shared
            .subscribeToTopic(topic: AppRes.liveStreamingTopic);
      } else {
        FirebaseNotificationManager.shared.unsubscribeToTopic();
        FirebaseNotificationManager.shared
            .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
      }
      SessionManager.instance.setUser(user.data);
    }
    return user;
  }

  Future<UserModel> fakeUserLogin(
      {required String? email,
      required String password,
      required String deviceToken}) async {
    Map<String, dynamic> map = {};
    map[Urls.identity] = email;
    map[Urls.password] = password;
    map[Urls.deviceToken] = deviceToken;
    map[Urls.deviceType] = AppPlatform.isAndroid ? Urls.aOne : Urls.aTwo;
    http.Response response = await http.post(
      Uri.parse(Urls.aFakeUserLogin),
      headers: headers,
      body: map,
    );
    UserModel user = UserModel.fromJson(jsonDecode(response.body));

    if (user.status == true) {
      if (user.data?.isNotification == 1) {
        FirebaseNotificationManager.shared.subscribeToTopic();
        FirebaseNotificationManager.shared
            .subscribeToTopic(topic: AppRes.liveStreamingTopic);
      } else {
        FirebaseNotificationManager.shared.unsubscribeToTopic();
        FirebaseNotificationManager.shared
            .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
      }
      SessionManager.instance.setUser(user.data);
    }
    return user;
  }

  Future<ApplyForLive> applyForLive(File? introVideo, String aboutYou,
      String languages, String socialLinks) async {
    var request = http.MultipartRequest(
      Urls.post,
      Uri.parse(Urls.aApplyForLive),
    );
    request.headers.addAll(headers);
    request.fields[Urls.userId] = myUserId.toString();
    request.fields[Urls.aSocialLink] = socialLinks;
    if (introVideo != null) {
      if (kIsWeb) {
        final bytes = await introVideo.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(Urls.aIntroVideo, bytes,
              filename: introVideo.path.split("/").last),
        );
      } else {
        request.files.add(
          http.MultipartFile(Urls.aIntroVideo,
              introVideo.readAsBytes().asStream(), introVideo.lengthSync(),
              filename: introVideo.path.split("/").last),
        );
      }
    }
    request.fields[Urls.aLanguages] = languages;
    request.fields[Urls.aAboutYou] = aboutYou;

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    final responseJson = jsonDecode(respStr);
    ApplyForLive applyForLive = ApplyForLive.fromJson(responseJson);
    return applyForLive;
  }

  Future<UserModel> updateProfile({
    String? fullName,
    int? gender,
    String? age,
    String? dob,
    double? distancePreference,
    dynamic relationshipGoalId,
    String? religionKey,
    String? languageKeys,
    List<XFile>? images,
    String? live,
    String? bio,
    List<String>? interest,
    String? latitude,
    String? longitude,
    String? instagram,
    String? facebook,
    String? youtube,
    String? userName,
    int? genderPreferred,
    double? ageMin,
    double? ageMax,
    List<String>? deleteImageIds,
    String? about,
    int? isVerified,
    String? hiddenUserIds,
    String? country,
    String? state,
    String? city,
    String? appLanguage,
  }) async {
    var request = http.MultipartRequest(
      Urls.post,
      Uri.parse(Urls.aUpdateProfile),
    );
    request.headers.addAll({
      Urls.apiKeyName: ConstRes.apiKey,
    });
    request.fields[Urls.userId] = myUserId.toString();
    if (live != null) {
      request.fields[Urls.live] = live;
    }
    if (genderPreferred != null) {
      request.fields[Urls.genderPreferred] = '$genderPreferred';
    }
    if (distancePreference != null) {
      request.fields[Urls.distancePreference] = '${distancePreference.toInt()}';
    }
    if (relationshipGoalId != null) {
      if (relationshipGoalId is List) {
        request.fields[Urls.relationshipGoalId] = relationshipGoalId.join(',');
      } else {
        request.fields[Urls.relationshipGoalId] = '$relationshipGoalId';
      }
    }
    if (religionKey != null) {
      request.fields[Urls.religionKey] = religionKey;
    }
    if (languageKeys != null) {
      request.fields[Urls.languageKeys] = languageKeys;
    }
    if (bio != null) {
      request.fields[Urls.bio] = bio;
    }
    if (age != null) {
      request.fields[Urls.age] = age;
    }
    if (country != null) {
      request.fields[Urls.country] = country;
    }
    if (state != null) {
      request.fields[Urls.state] = state;
    }
    if (city != null) {
      request.fields[Urls.city] = city;
    }
    if (dob != null) {
      request.fields[Urls.dob] = dob;
    }
    if (isVerified != null) {
      request.fields[Urls.isVerified] = '$isVerified';
    }
    if (fullName != null) {
      request.fields[Urls.fullName] = fullName;
    }
    if (userName != null) {
      request.fields[Urls.userName] = userName;
    }
    if (instagram != null) {
      request.fields[Urls.instagram] = instagram;
    }
    if (ageMin != null) {
      request.fields[Urls.agePreferredMin] = '${ageMin.toInt()}';
    }
    if (ageMax != null) {
      request.fields[Urls.agePreferredMax] = '${ageMax.toInt()}';
    }
    if (facebook != null) {
      request.fields[Urls.facebook] = facebook;
    }
    if (youtube != null) {
      request.fields[Urls.youtube] = youtube;
    }
    if (latitude != null) {
      request.fields[Urls.latitude] = latitude;
    }
    if (longitude != null) {
      request.fields[Urls.longitude] = longitude;
    }
    if (interest != null) {
      request.fields[Urls.interests] = interest.join(",");
    }
    if (gender != null) {
      request.fields[Urls.gender] = '$gender';
    }
    if (about != null) {
      request.fields[Urls.about] = about;
    }
    if (hiddenUserIds != null) {
      request.fields[Urls.hiddenUserIds] = hiddenUserIds;
    }
    if (appLanguage != null) {
      request.fields[Urls.appLanguage] = appLanguage;
    }
    List<http.MultipartFile> newList = <http.MultipartFile>[];
    Map<String, String> map = {};
    if (deleteImageIds != null) {
      for (int i = 0; i < deleteImageIds.length; i++) {
        map['${Urls.deleteImagesId}[$i]'] = deleteImageIds[i];
      }
    }
    request.fields.addAll(map);
    if (images != null) {
      for (int i = 0; i < images.length; i++) {
        if (kIsWeb) {
          final bytes = await images[i].readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(Urls.images, bytes,
              filename: images[i].path.split('/').last);
          newList.add(multipartFile);
        } else {
          File imageFile = File(images[i].path);
          var multipartFile = http.MultipartFile(Urls.images,
              imageFile.readAsBytes().asStream(), imageFile.lengthSync(),
              filename: imageFile.path.split('/').last);
          newList.add(multipartFile);
        }
      }
    }
    log(request.fields.toString());
    request.files.addAll(newList);
    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    final responseJson = jsonDecode(respStr);
    UserModel updateProfile = UserModel.fromJson(responseJson);
    SessionManager.instance.setUser(updateProfile.data);
    SessionManager.instance.updateFirebase();
    return updateProfile;
  }

  Future<UserModel> getProfile({int? userID}) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aGetProfile), headers: headers, body: {
      Urls.userId: '${userID ?? myUserId}',
      Urls.myUserId: myUserId.toString(),
    });

    UserModel profile = UserModel.fromJson(jsonDecode(response.body));
    if (profile.status == true && myUserId == profile.data?.id.toString()) {
      SessionManager.instance.setUser(profile.data);
    }

    return profile;
  }

  Future<UserModel> fetchMyUserProfile() async {
    try {
      http.Response response =
          await http.post(Uri.parse(Urls.aFetchMyUserProfile), headers: headers, body: {
        Urls.userId: myUserId,
      });
      UserModel profile = UserModel.fromJson(jsonDecode(response.body));
      if (profile.status == true) {
        SessionManager.instance.setUser(profile.data);
      }
      return profile;
    } catch (e) {
      log('fetchMyUserProfile error: $e');
      return UserModel(status: false);
    }
  }

  Future<UserModel> onOffNotification(int state) async {
    http.Response response = await http.post(Uri.parse(Urls.aOnOffNotification),
        headers: headers,
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aState: state.toString()
        });
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> onOffShowMeOnMap(int state) async {
    http.Response response = await http.post(Uri.parse(Urls.aOnOffShowMeOnMap),
        headers: headers,
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aState: state.toString()
        });
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> onOffAnonymous(int? state) async {
    http.Response response = await http.post(Uri.parse(Urls.aOnOffAnonymous),
        headers: headers,
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aState: state.toString()
        });

    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<Report> addReport(String reason, String description, int? id) async {
    http.Response response = await http.post(Uri.parse(Urls.aAddUserReport),
        headers: headers,
        body: {
          Urls.aReason: reason,
          Urls.aDescription: description,
          Urls.userId: id.toString(),
          'reported_by': SessionManager.instance.getUserID().toString(),
          'my_user_id': SessionManager.instance.getUserID().toString(),
        });
    return Report.fromJson(jsonDecode(response.body));
  }

  Future<AdminNotification> adminNotification(int start) async {
    http.Response response = await http
        .post(Uri.parse(Urls.aGetAdminNotification), headers: headers, body: {
      Urls.aStart: start.toString(),
      Urls.aCount: '${AppRes.paginationLimit}'
    });
    return AdminNotification.fromJson(jsonDecode(response.body));
  }

  Future<UserNotificationModel> getUserNotification(int start) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aGetUserNotification), headers: headers, body: {
      Urls.userId: myUserId.toString(),
      Urls.aStart: start.toString(),
      Urls.aCount: '${AppRes.paginationLimit}',
    });
    // print('error : ${response.body}');
    return UserNotificationModel.fromJson(jsonDecode(response.body));
  }

  Future<SettingModel> getSettingData() async {
    try {
      http.Response response = await http.post(
        Uri.parse(Urls.aGetSettingData),
        headers: headers,
      );
      SettingModel setting = SettingModel.fromJson(jsonDecode(response.body));
      if (setting.status == true) {
        SessionManager.instance.setSettings(setting.data);
      }
      return setting;
    } catch (e) {
      log('getSettingData error: $e');
      return SettingModel(status: false);
    }
  }

  Future<Map<String, dynamic>> initializePaystack({
    required String email,
    required double amount,
    required int diamonds,
    required String planId,
    required String type,
    int months = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Urls.aPaystackInitialize),
        headers: headers,
        body: {
          'email': email,
          'amount': amount.toString(),
          'diamonds': diamonds.toString(),
          'plan_id': planId,
          'type': type,
          'months': months.toString(),
          'user_id': SessionManager.instance.getUserID().toString(),
        },
      );
      final json = jsonDecode(response.body);
      if (json['status'] == true && json['data'] != null) {
        final data = Map<String, dynamic>.from(json['data']);
        data['status'] = true;
        return data;
      } else {
        return {
          'status': false,
          'message': json['message'] ?? 'Paystack initialization failed',
        };
      }
    } catch (e) {
      log('initializePaystack error: $e');
      return {
        'status': false,
        'message': 'Network error connecting to payment gateway: $e',
      };
    }
  }

  Future<UserModel> verifyPaystack({
    required String reference,
    int diamonds = 0,
    int months = 1,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Urls.aPaystackVerify),
        headers: headers,
        body: {
          'reference': reference,
          'user_id': SessionManager.instance.getUserID().toString(),
          'diamonds': diamonds.toString(),
          'months': months.toString(),
          'type': type,
        },
      );
      final model = UserModel.fromJson(jsonDecode(response.body));
      if (model.status == true && model.data != null) {
        SessionManager.instance.setUser(model.data);
      }
      return model;
    } catch (e) {
      log('verifyPaystack error: $e');
      return UserModel(status: false, message: e.toString());
    }
  }

  Future<SearchUser> searchUser(
      {required String searchKeyword, required int start}) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aSearchUsers), headers: headers, body: {
      Urls.userId: "${SessionManager.instance.getUserID()}",
      Urls.aKeyword: searchKeyword,
      Urls.aStart: start.toString(),
      Urls.aCount: '${AppRes.paginationLimit}'
    });
    SearchUser searchUser = SearchUser.fromJson(jsonDecode(response.body));
    return searchUser;
  }

  Future<SearchUserById> searchUserById(
      {required String searchKeyword,
      int? interestId,
      required int start}) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aSearchUsersForInterest), headers: headers, body: {
      Urls.userId: "${SessionManager.instance.getUserID()}",
      Urls.aKeyword: searchKeyword,
      Urls.aStart: start.toString(),
      Urls.aCount: '${AppRes.paginationLimit}',
      Urls.aInterestId: interestId.toString()
    });
    return SearchUserById.fromJson(jsonDecode(response.body));
  }

  Future<LikeModel> updateLikedProfile(int? profileId) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aUpdateLikedProfile), headers: headers, body: {
      Urls.userId: '$profileId',
      Urls.myUserId: myUserId,
    });
    LikeModel likeResponse = LikeModel.fromJson(jsonDecode(response.body));

    return likeResponse;
  }

  Future<Report> likedProfile(int? profileId) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aLikedProfile), headers: headers, body: {
      Urls.userId: '$profileId',
      Urls.myUserId: myUserId,
    });
    Report likeResponse = Report.fromJson(jsonDecode(response.body));
    return likeResponse;
  }

  Future<Report> dislikedProfile(int? profileId) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aDislikedProfile), headers: headers, body: {
      Urls.userId: '$profileId',
      Urls.myUserId: myUserId,
    });
    Report likeResponse = Report.fromJson(jsonDecode(response.body));
    return likeResponse;
  }

  Future<UserModel> updateSaveProfile(int? profileId, {bool? setSaved}) async {
    var userData = SessionManager.instance.getUser();
    List<String> list = (userData?.savedProfile ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (profileId != null) {
      String idStr = profileId.toString();
      if (setSaved != null) {
        if (setSaved) {
          if (!list.contains(idStr)) list.add(idStr);
        } else {
          list.remove(idStr);
        }
      } else {
        if (list.contains(idStr)) {
          list.remove(idStr);
        } else {
          list.add(idStr);
        }
      }
    }
    String updatedSavedProfiles = list.join(',');
    if (userData != null) {
      userData.savedProfile = updatedSavedProfiles;
      SessionManager.instance.setUser(userData);
    }

    // Send the updated saved profiles to the server
    http.Response response = await http.post(
      Uri.parse(Urls.aUpdateSavedProfile),
      headers: {Urls.apiKeyName: ConstRes.apiKey},
      body: {
        Urls.userId: myUserId.toString(),
        Urls.aProfiles: updatedSavedProfiles,
      },
    );

    // Parse the response and return the result
    UserModel updateSavedProfile =
        UserModel.fromJson(jsonDecode(response.body));
    if (updateSavedProfile.status == true && updateSavedProfile.data != null) {
      SessionManager.instance.setUser(updateSavedProfile.data);
    } else if (userData != null) {
      userData.savedProfile = updatedSavedProfiles;
      SessionManager.instance.setUser(userData);
    }

    return updateSavedProfile;
  }

  Future<FetchLiveStreamHistory> fetchAllLiveStreamHistory(int starting) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aFetchAllLiveStreamHistory), headers: headers, body: {
      Urls.userId: myUserId.toString(),
      Urls.aStart: '$starting',
      Urls.aCount: '${AppRes.paginationLimit}'
    });
    return FetchLiveStreamHistory.fromJson(jsonDecode(response.body));
  }

  Future<Verification> applyForVerification(
      File? photo, File? docImage, String fullName, String docType) async {
    var request =
        http.MultipartRequest(Urls.post, Uri.parse(Urls.aApplyForVerification));
    request.headers.addAll(headers);
    request.fields[Urls.userId] = myUserId.toString();
    request.fields[Urls.aDocumentType] = docType;
    if (photo != null) {
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(Urls.aSelfie, bytes,
              filename: photo.path.split("/").last),
        );
      } else {
        request.files.add(
          http.MultipartFile(
              Urls.aSelfie, photo.readAsBytes().asStream(), photo.lengthSync(),
              filename: photo.path.split("/").last),
        );
      }
    }
    if (docImage != null) {
      if (kIsWeb) {
        final bytes = await docImage.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(Urls.aDocument, bytes,
              filename: docImage.path.split("/").last),
        );
      } else {
        request.files.add(
          http.MultipartFile(Urls.aDocument, docImage.readAsBytes().asStream(),
              docImage.lengthSync(),
              filename: docImage.path.split("/").last),
        );
      }
    }
    request.fields[Urls.fullName] = fullName;

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    final responseJson = jsonDecode(respStr);
    Verification applyForVerification = Verification.fromJson(responseJson);
    return applyForVerification;
  }

  Future<DeleteAccount> deleteAccount(int? deleteId) async {
    http.Response response = await http.post(Uri.parse(Urls.aDeleteMyAccount),
        headers: headers,
        body: {Urls.userId: deleteId.toString()});
    DeleteAccount deleteAccount =
        DeleteAccount.fromJson(jsonDecode(response.body));
    if (deleteAccount.status == true) {
      FirebaseNotificationManager.shared
          .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
    }
    return deleteAccount;
  }

  Future<StoreFileGivePath> getStoreFileGivePath({
    dynamic image,
    Uint8List? bytes,
    String? filename,
  }) async {
    var request =
        http.MultipartRequest(Urls.post, Uri.parse(Urls.aStorageFileGivePath));
    request.headers.addAll(headers);

    Uint8List? fileBytes = bytes;
    String finalName =
        filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (fileBytes == null && image != null) {
      if (image is XFile) {
        fileBytes = await image.readAsBytes();
        finalName = filename ?? image.name;
      } else if (image is Uint8List) {
        fileBytes = image;
      } else if (kIsWeb) {
        try {
          if (image is File) {
            fileBytes = await XFile(image.path).readAsBytes();
            finalName = filename ?? image.path.split("/").last;
          }
        } catch (_) {}
      } else if (image is File) {
        try {
          fileBytes = await image.readAsBytes();
          finalName = filename ?? image.path.split("/").last;
        } catch (_) {}
      }
    }

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          Urls.aFile,
          fileBytes,
          filename: finalName,
        ),
      );
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    final responseJson = jsonDecode(respStr);
    StoreFileGivePath applyForVerification =
        StoreFileGivePath.fromJson(responseJson);

    return applyForVerification;
  }

  Future<MinusCoinFromWallet> minusCoinFromWallet(int? amount) async {
    http.Response response = await http
        .post(Uri.parse(Urls.aMinusCoinsFromWallet), headers: headers, body: {
      Urls.userId: myUserId.toString(),
      Urls.aAmount: amount.toString()
    });
    getProfile();
    return MinusCoinFromWallet.fromJson(jsonDecode(response.body));
  }

  Future<MinusCoinFromWallet> addCoinFromWallet(num? amount) async {
    http.Response response = await http.post(
      Uri.parse(Urls.aAddCoinsToWallet),
      headers: {Urls.apiKeyName: ConstRes.apiKey},
      body: {Urls.userId: myUserId.toString(), Urls.aAmount: amount.toString()},
    );

    return MinusCoinFromWallet.fromJson(jsonDecode(response.body));
  }

  Future<GetDiamondPack> getDiamondPack() async {
    http.Response response =
        await http.post(Uri.parse(Urls.aGetDiamondPacks), headers: headers, body: {
      Urls.userId: myUserId.toString(),
      Urls.aStart: '0',
      Urls.aCount: '${AppRes.paginationLimit}'
    });
    return GetDiamondPack.fromJson(jsonDecode(response.body));
  }

  Future<AddLiveStreamHistory> addLiveStreamHistory(
      {required String streamFor,
      required String startedAt,
      required String amountCollected}) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aAddLiveStreamHistory), headers: headers, body: {
      Urls.userId: myUserId.toString(),
      Urls.aStreamedFor: streamFor,
      Urls.aStartedAt: startedAt,
      Urls.aAmountCollected: amountCollected
    });
    return AddLiveStreamHistory.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> getRandomProfile({required int gender}) async {
    http.Response response = await http.post(Uri.parse(Urls.aGetRandomProfile),
        headers: headers,
        body: {
          Urls.userId: myUserId.toString(),
          Urls.gender: gender.toString()
        });

    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<GetExploreScreen> getExplorePageProfileList() async {
    http.Response response = await http.post(
        Uri.parse(Urls.aGetExplorePageProfileList),
        headers: headers,
        body: {Urls.userId: myUserId.toString()});
    log(response.body);
    return GetExploreScreen.fromJson(jsonDecode(response.body));
  }

  Future<FetchRedeemRequest> fetchRedeemRequest() async {
    http.Response response = await http.post(
        Uri.parse(Urls.aFetchMyRedeemRequests),
        headers: headers,
        body: {Urls.userId: myUserId.toString()});
    return FetchRedeemRequest.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> updateBlockList(int? blockProfileId) async {
    var userData = SessionManager.instance.getUser();
    String? blockProfile = userData?.blockedUsers;
    List<int> blockProfileList = [];
    if (blockProfile != null &&
        blockProfile.isNotEmpty &&
        !blockProfile.contains(blockProfileId.toString())) {
      blockProfile += ',$blockProfileId';
    } else {
      if (blockProfile == null || blockProfile.isEmpty) {
        blockProfile = blockProfileId.toString();
      } else if (blockProfile.contains(blockProfileId.toString())) {
        for (int i = 0; i < blockProfile.split(',').length; i++) {
          blockProfileList.add(int.parse(blockProfile.split(',')[i]));
        }
        for (int i = 0; i < blockProfile.split(',').length; i++) {
          if (blockProfile.split(',')[i] == blockProfileId.toString()) {
            blockProfileList.removeAt(i);
            break;
          }
        }
        blockProfile = blockProfileList.join(",");
      }
    }

    http.Response response = await http.post(Uri.parse(Urls.aUpdateBlockList),
        headers: headers,
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aBlockedUsers: blockProfile
        });
    UserModel updateBlockProfile =
        UserModel.fromJson(jsonDecode(response.body));
    SessionManager.instance.setUser(updateBlockProfile.data);
    return updateBlockProfile;
  }

  Future<FetchUserCoordinate> getUserByLatLong(
      {required double latitude,
      required double longitude,
      required int km}) async {
    http.Response response =
        await http.post(Uri.parse(Urls.aFetchUsersByCoordinates), headers: {
      Urls.apiKeyName: ConstRes.apiKey
    }, body: {
      Urls.lat: latitude.toString(),
      Urls.long: longitude.toString(),
      Urls.aKm: km.toString()
    });
    return FetchUserCoordinate.fromJson(jsonDecode(response.body));
  }

  Future<void> pushNotification({
    String? token,
    String? topic,
    num? deviceType,
    required String title,
    required String body,
    String? conversationId,
    bool isLiveStreaming = false,
    Map<String, dynamic>? liveStreamUserData,
  }) async {
    final bool isIOS = deviceType == 2;

    // Prepare base notification data
    final Map<String, dynamic> messageData = {
      "apns": {
        "headers": {"apns-priority": "10"},
        "payload": {
          "aps": {"sound": "default", "content-available": 1}
        }
      },
      "data": isLiveStreaming
          ? (liveStreamUserData ?? {})
          : {
              if (conversationId != null) Urls.aConversationId: conversationId,
              "body": body,
              "title": title
            },
    };

    // iOS needs explicit notification payload
    if (isIOS) {
      messageData["notification"] = {
        "body": body,
        "title": title,
      };
    }

    // Set target
    if (token != null && token.isNotEmpty) {
      messageData["token"] = token;
    } else if (isLiveStreaming && topic != null && topic.isNotEmpty) {
      messageData["topic"] = topic;
    } else {
      log("Notification not sent: Missing token/topic.");
      return;
    }

    final Map<String, dynamic> inputData = {"message": messageData};

    log("Sending push notification: $inputData");

    try {
      final response = await http.post(
        Uri.parse(Urls.aNotificationUrl),
        headers: headers,
        body: json.encode(inputData),
      );

      log("Notification response: ${response.body}");
    } catch (e) {
      log("Error sending notification: $e");
    }
  }

  Future<void> sendLocalizedPushNotification({
    required String key,
    required UserData? userData,
    required String? deviceToken,
  }) async {
    final languageCode =
        (userData?.appLanguage ?? AppPlatform.languageCode).toLowerCase();
    if (!S.delegate.isSupported(Locale(languageCode))) return;

    try {
      final data =
          await rootBundle.loadString('lib/l10n/intl_$languageCode.arb');
      final translations = jsonDecode(data) as Map<String, dynamic>;

      pushNotification(
        title: userData?.fullname ?? '',
        body: translations[key] ?? '',
        deviceType: userData?.deviceType,
        token: deviceToken,
      );
    } catch (e) {
      log('Error sending localized push notification: $e');
    }
  }

  Future<Report> logoutUser() async {
    http.Response response = await http.post(Uri.parse(Urls.aLogoutUser),
        headers: headers,
        body: {Urls.userId: myUserId.toString()});
    Report report = Report.fromJson(jsonDecode(response.body));
    if (report.status == true) {
      FirebaseNotificationManager.shared
          .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
    }
    return report;
  }

  Future<Agora> agoraListStreamingCheck(
      String channelName, String authToken, String agoraAppId) async {
    log('$channelName\n$agoraAppId\n$authToken');
    http.Response response = await http.get(
        Uri.parse(
            'https://api.agora.io/dev/v1/channel/user/$agoraAppId/$channelName'),
        headers: {'Authorization': 'Basic $authToken'});
    return Agora.fromJson(jsonDecode(response.body));
  }

  Future<SearchUser> fetchSavedProfiles() async {
    http.Response response = await http.post(
        Uri.parse(Urls.aFetchSavedProfiles),
        headers: headers,
        body: {Urls.userId: myUserId.toString()});
    return SearchUser.fromJson(jsonDecode(response.body));
  }

  Future<SearchUser> fetchLikedProfiles() async {
    http.Response response = await http.post(
        Uri.parse(Urls.aFetchLikedProfiles),
        headers: headers,
        body: {Urls.userId: myUserId});
    return SearchUser.fromJson(jsonDecode(response.body));
  }

  Future<SearchUser> fetchBlockedProfiles() async {
    http.Response response = await http.post(
        Uri.parse(Urls.aFetchBlockedProfiles),
        headers: headers,
        body: {Urls.userId: myUserId.toString()});
    // print(response.body);
    return SearchUser.fromJson(jsonDecode(response.body));
  }

  Future<void> getIPPlaceDetail(
      {required Function(PlaceDetail detail) onCompletion}) async {
    callPost(
        completion: (response) {
          PlaceDetail detail = PlaceDetail.fromJson(response);
          log(detail.toJson().toString());
          onCompletion.call(detail);
        },
        url: Urls.ipApi);
  }

  void callPost({
    required Function(Object response) completion,
    required String url,
    Map<String, dynamic>? param,
  }) {
    Map<String, String> params = {};
    param?.forEach((key, value) {
      params[key] = "$value";
    });
    log("❗️{URL}:  $url");
    log("❗️{PARAMETERS}:  $params");
    http.post(Uri.parse(url), headers: headers, body: params).then(
      (value) {
        log('❗️RESPONSE:  ${value.statusCode}');
        var response = jsonDecode(value.body);
        completion(response);
      },
    );
  }

  Future<GetPackage> getPackage() async {
    http.Response response = await http.post(
      Uri.parse(Urls.aGetPackage),
      headers: headers,
    );
    return GetPackage.fromJson(jsonDecode(response.body));
  }

  void multiPartCallApi(
      {required String url,
      Map<String, dynamic>? param,
      Map<String, List<XFile?>>? filesMap,
      required Function(Object response) completion}) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));

    Map<String, String> params = {};
    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = value[i];
        }
      } else {
        params[key] = "$value";
      }
    });

    request.fields.addAll(params);
    request.headers.addAll(headers);
    if (filesMap != null) {
      for (var entry in filesMap.entries) {
        String keyName = entry.key;
        List<XFile?> files = entry.value;
        for (var xFile in files) {
          if (xFile != null && xFile.path.isNotEmpty) {
            if (kIsWeb) {
              final bytes = await xFile.readAsBytes();
              var multipartFile = http.MultipartFile.fromBytes(keyName, bytes,
                  filename: xFile.name);
              request.files.add(multipartFile);
            } else {
              File file = File(xFile.path);
              var multipartFile = http.MultipartFile(
                  keyName, file.readAsBytes().asStream(), file.lengthSync(),
                  filename: xFile.name);
              request.files.add(multipartFile);
            }
          }
        }
      }
    }
    log(param.toString());
    log(filesMap.toString());
    try {
      var value = await request.send().timeout(const Duration(seconds: 90));
      log('StatusCode :: ${value.statusCode}');
      var respStr = await value.stream.bytesToString();
      var response = jsonDecode(respStr);
      completion(response);
    } catch (e) {
      log('multiPartCallApi error: $e');
      completion({'status': false, 'message': 'Upload request failed or timed out. Please try again.'});
    }
  }
}
