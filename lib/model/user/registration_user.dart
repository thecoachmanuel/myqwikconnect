// ignore_for_file: unnecessary_getters_setters

import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:orange_ui/service/extention/string_extention.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/story_view/controller/story_controller.dart';
import 'package:orange_ui/story_view/widgets/story_view.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';

class UserModel {
  UserModel({
    bool? status,
    String? message,
    bool? isNew,
    UserData? data,
  }) {
    _status = status;
    _message = message;
    _isNew = isNew;
    _data = data;
  }

  UserModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _isNew = json['is_new'] ?? json['isNew'];
    _data = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }

  bool? _status;
  String? _message;
  bool? _isNew;
  UserData? _data;

  UserModel copyWith({
    bool? status,
    String? message,
    bool? isNew,
    UserData? data,
  }) =>
      UserModel(
        status: status ?? _status,
        message: message ?? _message,
        isNew: isNew ?? _isNew,
        data: data ?? _data,
      );

  bool? get status => _status;

  String? get message => _message;

  bool? get isNew => _isNew;

  UserData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class UserData {
  UserData({
    this.id,
    this.isBlock,
    this.gender = GenderType.male,
    this.dob,
    this.savedProfile,
    this.likedProfile,
    this.interests,
    this.identity,
    this.username,
    this.fullname,
    this.instagram,
    this.youtube,
    this.facebook,
    this.bio,
    this.about,
    this.latitude,
    this.longitude,
    this.loginType,
    this.deviceToken,
    this.blockedUsers,
    this.wallet,
    this.totalCollected,
    this.totalStreams,
    this.deviceType,
    this.isNotification,
    this.isVerified,
    this.showOnMap,
    this.anonymous,
    this.isVideoCall,
    this.canGoLive,
    this.isLiveNow,
    this.isFake,
    this.password,
    this.following,
    this.followers,
    this.genderPreferred = GenderType.male,
    this.agePreferredMin,
    this.agePreferredMax,
    this.distancePreference,
    dynamic relationshipGoalId,
    this.religionKey,
    this.languageKeys,
    this.createdAt,
    this.updatedAt,
    this.images,
    this.isLiked,
    this.followingStatus,
    this.matchedInterests,
    this.matchedLanguages,
    this.matchedRelationshipGoalId,
    this.matchedReligion,
    this.matchScore,
    this.hiddenUserIds,
    this.country,
    this.state,
    this.city,
    this.appLanguage,
  }) {
    if (relationshipGoalId != null) {
      relationshipGoalIds = relationshipGoalId.toString();
    }
  }

  UserData.fromJson(dynamic json) {
    if (json is! Map) return;
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    isBlock = json['is_block'] is int ? json['is_block'] : int.tryParse(json['is_block']?.toString() ?? '');
    gender = json['gender'] == null || json['gender'] == 'null'
        ? GenderType.male
        : GenderType.fromString(json['gender']);
    dob = json['dob']?.toString();
    savedProfile = json['savedprofile']?.toString();
    likedProfile = json['likedprofile']?.toString();
    interests = json['interests']?.toString();
    identity = json['identity']?.toString();
    username = json['username']?.toString();
    fullname = json['fullname']?.toString();
    instagram = json['instagram']?.toString();
    youtube = json['youtube']?.toString();
    facebook = json['facebook']?.toString();
    bio = json['bio']?.toString();
    about = json['about']?.toString();
    latitude = json['lattitude']?.toString() ?? json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    loginType = json['login_type'] is int ? json['login_type'] : int.tryParse(json['login_type']?.toString() ?? '');
    deviceToken = json['device_token']?.toString();
    blockedUsers = json['blocked_users']?.toString();
    wallet = json['wallet'] is int
        ? json['wallet']
        : (json['wallet'] is num ? (json['wallet'] as num).toInt() : int.tryParse(json['wallet']?.toString() ?? ''));
    totalCollected = json['total_collected'] is int
        ? json['total_collected']
        : (json['total_collected'] is num
            ? (json['total_collected'] as num).toInt()
            : int.tryParse(json['total_collected']?.toString() ?? ''));
    totalStreams = json['total_streams'] is int
        ? json['total_streams']
        : (json['total_streams'] is num
            ? (json['total_streams'] as num).toInt()
            : int.tryParse(json['total_streams']?.toString() ?? ''));
    deviceType = json['device_type'] is int ? json['device_type'] : int.tryParse(json['device_type']?.toString() ?? '');
    isNotification = json['is_notification'] is int ? json['is_notification'] : int.tryParse(json['is_notification']?.toString() ?? '');
    isVerified = json['is_verified'] is int ? json['is_verified'] : int.tryParse(json['is_verified']?.toString() ?? '');
    showOnMap = json['show_on_map'] is int ? json['show_on_map'] : int.tryParse(json['show_on_map']?.toString() ?? '');
    anonymous = json['anonymous'] is int ? json['anonymous'] : int.tryParse(json['anonymous']?.toString() ?? '');
    isVideoCall = json['is_video_call'] is int ? json['is_video_call'] : int.tryParse(json['is_video_call']?.toString() ?? '');
    canGoLive = json['can_go_live'] is int ? json['can_go_live'] : int.tryParse(json['can_go_live']?.toString() ?? '');
    isLiveNow = json['is_live_now'] is int ? json['is_live_now'] : int.tryParse(json['is_live_now']?.toString() ?? '');
    isFake = json['is_fake'] is int ? json['is_fake'] : int.tryParse(json['is_fake']?.toString() ?? '');
    password = json['password']?.toString();
    following = json['following'] is int ? json['following'] : int.tryParse(json['following']?.toString() ?? '');
    followers = json['followers'] is int ? json['followers'] : int.tryParse(json['followers']?.toString() ?? '');
    genderPreferred = json['gender_preferred'] == null || json['gender_preferred'] == 'null'
        ? GenderType.male
        : GenderType.fromString(json['gender_preferred']);
    agePreferredMin = json['age_preferred_min'] is int ? json['age_preferred_min'] : int.tryParse(json['age_preferred_min']?.toString() ?? '');
    agePreferredMax = json['age_preferred_max'] is int ? json['age_preferred_max'] : int.tryParse(json['age_preferred_max']?.toString() ?? '');
    distancePreference = json['distance_preference'] is int ? json['distance_preference'] : int.tryParse(json['distance_preference']?.toString() ?? '');
    relationshipGoalIds = json['relationship_goal_id']?.toString();
    religionKey = json['religion_key']?.toString();
    languageKeys = json['language_keys']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    if (json['is_like'] is bool) {
      isLiked = json['is_like'];
    } else if (json['is_like'] != null) {
      isLiked = json['is_like'] == 1 || json['is_like'] == '1' || json['is_like'] == 'true';
    } else {
      isLiked = false;
    }
    followingStatus = json['followingStatus'] is int ? json['followingStatus'] : int.tryParse(json['followingStatus']?.toString() ?? '');
    matchedInterests = json['matched_interests'] is int ? json['matched_interests'] : int.tryParse(json['matched_interests']?.toString() ?? '');
    matchedLanguages = json['matched_languages'] is int ? json['matched_languages'] : int.tryParse(json['matched_languages']?.toString() ?? '');
    matchedRelationshipGoalId = json['matched_relationship_goal_id'] is int ? json['matched_relationship_goal_id'] : int.tryParse(json['matched_relationship_goal_id']?.toString() ?? '');
    matchedReligion = json['matched_religion'] is int ? json['matched_religion'] : int.tryParse(json['matched_religion']?.toString() ?? '');
    matchScore = json['match_score'] is num ? (json['match_score'] as num).toInt() : int.tryParse(json['match_score']?.toString() ?? '');
    hiddenUserIds = json['hidden_user_ids']?.toString();
    country = json['country']?.toString();
    state = json['state']?.toString();
    city = json['city']?.toString();
    appLanguage = json['app_language']?.toString();
    isProfileComplete = json['is_profile_complete'] is int
        ? json['is_profile_complete']
        : int.tryParse(json['is_profile_complete']?.toString() ?? '');
    isPro = json['is_pro'] is int ? json['is_pro'] : int.tryParse(json['is_pro']?.toString() ?? '');
    proExpireDate = json['pro_expire_date']?.toString();
    if (json['images'] != null && json['images'] is List) {
      images = [];
      for (var v in json['images']) {
        if (v != null) {
          images?.add(Images.fromJson(v));
        }
      }
    }
    if (json['stories'] != null && json['stories'] is List) {
      story = [];
      for (var v in json['stories']) {
        if (v != null) {
          var s = Story.fromJson(v);
          s.user = this;
          story?.add(s);
        }
      }
    }
  }

  int? id;
  int? isBlock;
  GenderType gender = GenderType.male;
  String? savedProfile;
  String? likedProfile;
  String? interests;
  String? dob;
  String? identity;
  String? username;
  String? fullname;
  String? instagram;
  String? youtube;
  String? facebook;

  // String? live;
  String? bio;
  String? about;
  String? latitude;
  String? longitude;
  int? loginType;
  String? deviceToken;
  String? blockedUsers;
  int? wallet;
  int? totalCollected;
  int? totalStreams;
  int? deviceType;
  int? isNotification;
  int? isVerified;
  int? showOnMap;
  int? anonymous;
  int? isVideoCall;
  int? canGoLive;
  int? isLiveNow;
  int? isFake;
  String? password;
  int? following;
  int? followers;
  GenderType genderPreferred = GenderType.male;
  int? agePreferredMin;
  int? agePreferredMax;
  int? distancePreference;
  String? relationshipGoalIds;

  int? get relationshipGoalId {
    final list = relationshipGoalIdsList;
    return list.isNotEmpty ? list.first : null;
  }

  set relationshipGoalId(dynamic value) {
    if (value == null) {
      relationshipGoalIds = null;
    } else {
      relationshipGoalIds = value.toString();
    }
  }

  List<int> get relationshipGoalIdsList {
    if (relationshipGoalIds == null || relationshipGoalIds!.trim().isEmpty) return [];
    return relationshipGoalIds!
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }
  String? religionKey;
  String? languageKeys;
  String? createdAt;
  String? updatedAt;
  bool? isLiked;
  int? followingStatus;
  List<Images>? images;
  List<Story>? story;
  String? matchedInterests;
  String? matchedLanguages;
  int? matchedRelationshipGoalId;
  String? matchedReligion;
  int? matchScore;
  String? hiddenUserIds;
  String? country;
  String? state;
  String? city;
  String? appLanguage;
  int? isProfileComplete;
  int? isPro;
  String? proExpireDate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['is_block'] = isBlock;
    map['gender'] = gender.value;
    map['savedprofile'] = savedProfile;
    map['likedprofile'] = likedProfile;
    map['interests'] = interests;
    map['dob'] = dob;
    map['identity'] = identity;
    map['username'] = username;
    map['fullname'] = fullname;
    map['instagram'] = instagram;
    map['youtube'] = youtube;
    map['facebook'] = facebook;
    map['bio'] = bio;
    map['about'] = about;
    map['lattitude'] = latitude;
    map['longitude'] = longitude;
    map['login_type'] = loginType;
    map['device_token'] = deviceToken;
    map['blocked_users'] = blockedUsers;
    map['wallet'] = wallet;
    map['total_collected'] = totalCollected;
    map['total_streams'] = totalStreams;
    map['device_type'] = deviceType;
    map['is_notification'] = isNotification;
    map['is_verified'] = isVerified;
    map['show_on_map'] = showOnMap;
    map['anonymous'] = anonymous;
    map['is_video_call'] = isVideoCall;
    map['can_go_live'] = canGoLive;
    map['is_live_now'] = isLiveNow;
    map['is_fake'] = isFake;
    map['password'] = password;
    map['following'] = following;
    map['followers'] = followers;
    map['gender_preferred'] = genderPreferred.value;
    map['age_preferred_min'] = agePreferredMin;
    map['age_preferred_max'] = agePreferredMax;
    map['distance_preference'] = distancePreference;
    map['relationship_goal_id'] = relationshipGoalIds;
    map['religion_key'] = religionKey;
    map['language_keys'] = languageKeys;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['is_like'] = isLiked;
    map['matched_interests'] = matchedInterests;
    map['matched_languages'] = matchedLanguages;
    map['matched_relationship_goal_id'] = matchedRelationshipGoalId;
    map['matched_religion'] = matchedReligion;
    map['match_score'] = matchScore;
    map['followingStatus'] = followingStatus;
    map['hidden_user_ids'] = hiddenUserIds;
    map['country'] = country;
    map['state'] = state;
    map['city'] = city;
    map['app_language'] = appLanguage;
    map['is_pro'] = isPro;
    map['pro_expire_date'] = proExpireDate;
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
    if (story != null) {
      map['stories'] = story?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  List<SocialLink> get socialLinks {
    List<SocialLink> links = [];
    if (instagram != null && instagram!.isNotEmpty) {
      links.add(
          SocialLink(AssetRes.instagramLogo, S.current.instagram, instagram!));
    }
    if (facebook != null && facebook!.isNotEmpty) {
      links.add(
          SocialLink(AssetRes.facebookLogo, S.current.facebook, facebook!));
    }
    if (youtube != null && youtube!.isNotEmpty) {
      links.add(SocialLink(AssetRes.youtubeLogo, S.current.youtube, youtube!));
    }
    return links;
  }

  void followerCount(int value) {
    followers = (followers ?? 0) + value;
  }

  bool isAllStoryShown() {
    var isWatched = true;
    for (var element in (story ?? [])) {
      if (!element.isWatchedByMe()) {
        isWatched = false;
        break;
      }
    }
    return isWatched;
  }

  int get age => dob?.dateTimeToAge ?? 0;

  List<String> get interestList {
    final SettingData? settingData = SessionManager.instance.getSettings();
    final List<String> interestIds = interests?.split(',') ?? [];

    if (settingData == null || settingData.interests == null) return [];

    return (settingData.interests ?? [])
        .where((interest) => interestIds.contains(interest.id.toString()))
        .map((interest) => interest.title ?? '')
        .toList();
  }

  List<String> get relationShipGoalsTitles {
    final SettingData? settingData = SessionManager.instance.getSettings();
    final List<RelationshipGoals> items = settingData?.relationshipGoals ?? [];
    final ids = relationshipGoalIdsList;
    if (items.isEmpty || ids.isEmpty) return [];
    return items
        .where((goal) => goal.isDeleted == 0 && ids.contains(goal.id))
        .map((goal) => goal.title ?? '')
        .where((title) => title.isNotEmpty)
        .toList();
  }

  String? get relationShipGoal {
    final titles = relationShipGoalsTitles;
    if (titles.isEmpty) return null;
    return titles.join(', ');
  }

  List<String> get languageList {
    final SettingData? settingData = SessionManager.instance.getSettings();
    final List<Language> items = settingData?.language ?? [];
    List<String> ids =
        languageKeys?.split(',').map((e) => e.trim()).toList() ?? [];
    if (items.isEmpty || ids.isEmpty) return [];
    return items
        .where((language) =>
            language.isDeleted == 0 &&
            ids.contains(language.title?.removeEmojis.trim()))
        .map((language) => language.title ?? '')
        .toList();
  }

  bool get isSaved {
    String saved = SessionManager.instance.getUser()?.savedProfile ?? '';
    if (saved.isEmpty) return false;
    List<String> savedIds = saved.split(',');
    return savedIds.contains(id.toString());
  }

  set isSaved(bool saved) {
    final currentUser = SessionManager.instance.getUser();
    if (currentUser == null || id == null) return;

    final savedIds = (currentUser.savedProfile ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .toList();

    if (saved) {
      if (!savedIds.contains(id.toString())) {
        savedIds.add(id.toString());
      }
    } else {
      savedIds.remove(id.toString());
    }

    // Update the session user data
    currentUser.savedProfile = savedIds.join(',');
    SessionManager.instance.setUser(currentUser);
  }

  bool get isBlocked {
    String blocked = SessionManager.instance.getUser()?.blockedUsers ?? '';
    if (blocked.isEmpty) return false;
    List<String> blockedIds = blocked.split(',');
    return blockedIds.contains(id.toString());
  }

  set isBlocked(bool blocked) {
    final currentUser = SessionManager.instance.getUser();
    if (currentUser == null || id == null) return;

    final blockedIds = (currentUser.blockedUsers ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .toList();

    if (blocked) {
      if (!blockedIds.contains(id.toString())) {
        blockedIds.add(id.toString());
      }
    } else {
      blockedIds.remove(id.toString());
    }

    // Update the session user data
    currentUser.blockedUsers = blockedIds.join(',');
    SessionManager.instance.setUser(currentUser);
  }

  String get profileImage {
    return CommonFun.getProfileImage(images: images);
  }

  DateTime get ageToDateTime {
    if (dob == null) {
      return DateTime(DateTime.now().year - 18);
    }
    return DateTime.parse(dob!);
  }

  bool get isVerify {
    return isVerified == 2 || isVerified == 3;
  }

  String get address {
    final parts = [city, state, country]
        .where((s) => s != null && s.toString().trim().isNotEmpty && s.toString().trim() != 'null')
        .map((s) => s.toString().trim())
        .toList();
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return '';
  }

  String get locationDistance {
    UserData? myUserData = SessionManager.instance.getUser();
    double myLatitude = double.parse("${myUserData?.latitude ?? 0.0}");
    double myLongitude = double.parse("${myUserData?.longitude ?? 0.0}");
    double userLatitude = double.parse("${latitude ?? 0.0}");
    double userLongitude = double.parse("${longitude ?? 0.0}");

    double distance = CommonFun().calculateDistance(
        lat1: myLatitude,
        lon1: myLongitude,
        lat2: userLatitude,
        lon2: userLongitude);
    return distance.toStringAsFixed(2);
  }
}

class SocialLink {
  final String icon;
  final String title;
  final String link;

  SocialLink(this.icon, this.title, this.link);
}

class Images {
  Images({
    int? id,
    int? userId,
    String? image,
  }) {
    _id = id;
    _userId = userId;
    _image = image;
  }

  Images.fromJson(dynamic json) {
    if (json is String) {
      _image = json;
      _id = 0;
      _userId = 0;
      return;
    }
    if (json is Map) {
      _id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
      _userId = json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '');
      _image = json['image']?.toString();
    }
  }

  int? _id;
  int? _userId;
  String? _image;

  Images copyWith({
    int? id,
    int? userId,
    String? image,
  }) =>
      Images(
        id: id ?? _id,
        userId: userId ?? _userId,
        image: image ?? _image,
      );

  int? get id => _id;

  int? get userId => _userId;

  String? get image => _image;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['image'] = _image;
    return map;
  }
}

class Story {
  Story({
    int? id,
    int? userId,
    int? type,
    int? duration,
    String? content,
    String? viewByUserIds,
    String? createdAt,
    String? updatedAt,
    bool? storyView,
  }) {
    _id = id;
    _userId = userId;
    _type = type;
    _duration = duration;
    _content = content;
    _viewByUserIds = viewByUserIds;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _storyView = storyView;
  }

  Story.fromJson(dynamic json) {
    _id = json['id'];
    _userId = json['user_id'];
    _type = json['type'];
    _duration = json['duration'];
    _content = json['content'];
    _viewByUserIds = json['view_by_user_ids'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _storyView = json['storyView'];
  }

  int? _id;
  int? _userId;
  int? _type;
  int? _duration;
  String? _content;
  String? _viewByUserIds;
  String? _createdAt;
  String? _updatedAt;
  bool? _storyView;
  UserData? user;

  int? get id => _id;

  int? get userId => _userId;

  int? get type => _type;

  int? get duration => _duration;

  String? get content => _content;

  String? get viewByUserIds => _viewByUserIds;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  bool? get storyView => _storyView;

  set viewByUserIds(String? value) {
    _viewByUserIds = value;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['type'] = _type;
    map['duration'] = _duration;
    map['content'] = _content;
    map['view_by_user_ids'] = _viewByUserIds;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['storyView'] = _storyView;
    return map;
  }

  bool isWatchedByMe() {
    var arr = viewByUserIds?.split(',') ?? [];
    return arr.contains(SessionManager.instance.getUserID().toString());
  }

  List<String> viewedByUsersIds() {
    return viewByUserIds?.split(',') ?? [];
  }

  StoryItem toStoryItem(StoryController controller) {
    if (type == 1) {
      return StoryItem.pageVideo(
        (content ?? '').addBaseURL(),
        story: this,
        controller: controller,
        duration: Duration(seconds: (duration ?? 0).toInt()),
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    } else if (type == 0) {
      return StoryItem.pageImage(
        story: this,
        url: (content ?? '').addBaseURL(),
        controller: controller,
        duration: const Duration(seconds: AppRes.storyDuration),
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    } else {
      return StoryItem.text(
        story: this,
        title: content ?? '',
        backgroundColor: ColorRes.black,
        shown: isWatchedByMe(),
        id: id ?? 0,
        duration: const Duration(seconds: AppRes.storyDuration),
        viewedByUsersIds: viewedByUsersIds(),
      );
    }
  }

  DateTime get date => DateTime.parse(createdAt ?? '');
}
