import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/countries/select_country_controller.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen.dart';
import 'package:orange_ui/screen/create_profile_screen/view/add_photos.dart';
import 'package:orange_ui/screen/create_profile_screen/view/choose_religion.dart';
import 'package:orange_ui/screen/create_profile_screen/view/find_matches.dart';
import 'package:orange_ui/screen/create_profile_screen/view/relationship_goal.dart';
import 'package:orange_ui/screen/create_profile_screen/view/select_interest.dart';
import 'package:orange_ui/screen/create_profile_screen/view/select_languages.dart';
import 'package:orange_ui/screen/create_profile_screen/view/your_profile_ready.dart';
import 'package:orange_ui/screen/dashboard/dashboard_screen.dart';
import 'package:orange_ui/service/extention/datetime_extention.dart';
import 'package:orange_ui/service/extention/string_extention.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:stacked/stacked.dart';

class CreateProfileScreenViewModel extends BaseViewModel {
  TextEditingController fullnameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  final selectCountryController = Get.isRegistered<SelectCountryController>()
      ? Get.find<SelectCountryController>()
      : Get.put(SelectCountryController());

  DateTime selectedDob =
      DateTime.now().subtract(const Duration(days: 365 * 18));
  List<GenderType> genderTypes = GenderType.values;
  List<GenderType> preferredGenderTypes = GenderType.values;
  GenderType selectedPreferredGender = GenderType.male;
  GenderType selectedGenderType = GenderType.male;
  SettingData? settingData;

  List<RelationshipGoals> relationshipGoals = [];
  List<Interests> interestList = [];
  List<Interests> selectedInterest = [];
  List<Religions> religions = [];
  List<Language> languages = [];
  List<Language> selectedLanguages = [];
  List<Photo> images = [];
  List<Photo> deletedImages = [];

  List<RelationshipGoals> selectedRelationshipGoals = [];
  RelationshipGoals? get selectedRelationShipGoal =>
      selectedRelationshipGoals.isNotEmpty ? selectedRelationshipGoals.first : null;
  Religions? selectedReligion;

  RangeValues selectedAgeRange = const RangeValues(AppRes.ageMin, 35);
  double selectedDistance = AppRes.defaultDistancePreference;
  UserData? userData;

  void init(UserData userData) async {
    this.userData = userData;
    fullnameController = TextEditingController(text: userData.fullname ?? '');
    bioController = TextEditingController(text: userData.bio ?? '');
    aboutController = TextEditingController(text: userData.about ?? '');
    selectedDob = userData.ageToDateTime;
    settingData = SessionManager.instance.getSettings();
    initImage();

    _initializeUserPreferences();
    if (userData.country != null && userData.country!.trim().isNotEmpty) {
      selectCountryController.setLocationFromStrings(
        country: userData.country,
        state: userData.state,
        city: userData.city,
      );
    } else {
      selectCountryController.setLocationFromStrings(
        country: 'Nigeria',
      );
    }
    notifyListeners();
  }

  void onDateOfBirthTap(BuildContext context) {
    CommonFun.showDatePicker(
      context,
      selectedDob,
      onDateSelected: (time) {
        selectedDob = time;
        notifyListeners();
      },
    );
  }

  void onGenderTap(GenderType value) {
    selectedGenderType = value;
    notifyListeners();
  }

  void onPreferredGenderTap(GenderType preferredGenderTyp) {
    selectedPreferredGender = preferredGenderTyp;
    notifyListeners();
  }

  void onChangeAgeRange(RangeValues value) {
    selectedAgeRange = value;
    notifyListeners();
  }

  void onChangeDistance(double value) {
    selectedDistance = value;
    notifyListeners();
  }

  void onChangedRelationshipGoal(RelationshipGoals goal) {
    if (selectedRelationshipGoals.any((e) => e.id == goal.id)) {
      selectedRelationshipGoals.removeWhere((e) => e.id == goal.id);
    } else {
      selectedRelationshipGoals.add(goal);
    }
    notifyListeners();
  }

  void onSelectInterest(Interests interest) {
    final id = interest.id;
    if (id == null) return;

    final isAlreadySelected = selectedInterest.any((e) => e.id == id);

    if (isAlreadySelected) {
      selectedInterest.removeWhere((e) => e.id == id);
    } else {
      selectedInterest.add(interest);
    }

    notifyListeners();
  }

  void onSelectReligion(Religions religion) {
    selectedReligion = religion;
    notifyListeners();
  }

  void onSelectLanguages(Language language) {
    final id = language.id;
    if (id == null) return;

    final isAlreadySelected = selectedLanguages.any((e) => e.id == id);

    if (isAlreadySelected) {
      selectedLanguages.removeWhere((e) => e.id == id);
    } else {
      selectedLanguages.add(language);
    }

    notifyListeners();
  }

  void addImages() async {
    final int remainingSlots = AppRes.maxImages - images.length;
    if (remainingSlots == 0) return;
    if (remainingSlots == 1) {
      await ImagePicker()
          .pickImage(
              source: ImageSource.gallery,
              imageQuality: AppRes.quality,
              maxHeight: AppRes.maxHeight,
              maxWidth: AppRes.maxWidth)
          .then((value) {
        if (value != null) {
          images.add(Photo(-1, value));
          notifyListeners();
        }
      });
    } else {
      await ImagePicker()
          .pickMultiImage(
              imageQuality: AppRes.quality,
              limit: remainingSlots,
              maxHeight: AppRes.maxHeight,
              maxWidth: AppRes.maxWidth)
          .then((value) {
        if (value.isNotEmpty) {
          for (var element in value) {
            images.add(Photo(-1, element));
          }
          notifyListeners();
        }
      });
    }
  }

  void onDeleteImage(Photo file, int index) {
    if (file.id != -1) {
      deletedImages.add(file);
    }
    images.removeAt(index);
    notifyListeners();
  }

  void onContinueTap(CreateProfileContinueTap value) {
    switch (value) {
      case CreateProfileContinueTap.createProfile:
        createProfile();
        break;
      case CreateProfileContinueTap.findMatches:
        findMatches();
        break;
      case CreateProfileContinueTap.interest:
        chooseInterest();
        break;
      case CreateProfileContinueTap.relationGoal:
        chooseRelationshipGoal();
        break;
      case CreateProfileContinueTap.religion:
        chooseReligion();
        break;
      case CreateProfileContinueTap.language:
        chooseLanguages();
        break;
      case CreateProfileContinueTap.addPhoto:
        addPhotos();
        break;
      case CreateProfileContinueTap.finalProfile:
        tapFinalProfile();
        break;
    }
  }

  void createProfile() {
    if (fullnameController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterFullName);
    }
    if (bioController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterBio);
    }

    if (selectCountryController.selectedCountry.value == null) {
      if (selectCountryController.allCountries.isNotEmpty) {
        selectCountryController.selectCountry(
          country: selectCountryController.allCountries.first,
        );
      } else {
        return CommonUI.snackBar(message: S.current.pleaseSelectCountry);
      }
    }
    if (selectCountryController.selectedState.value == null) {
      if (selectCountryController.selectedStatesFromCountry.isNotEmpty) {
        selectCountryController.selectState(
          state: selectCountryController.selectedStatesFromCountry.first,
        );
      } else {
        return CommonUI.snackBar(message: S.current.pleaseSelectState);
      }
    }
    if (selectCountryController.selectedCity.value == null) {
      if (selectCountryController.selectedCitiesFromState.isNotEmpty) {
        selectCountryController.selectCity(
          city: selectCountryController.selectedCitiesFromState.first,
        );
      } else {
        return CommonUI.snackBar(message: S.current.pleaseSelectCity);
      }
    }

    if (settingData?.appdata?.isDating == 1) {
      selectedPreferredGender = selectedGenderType == GenderType.male
          ? GenderType.female
          : GenderType.male;
      notifyListeners();
      Get.to(() => FindMatches(model: this));
    } else {
      Get.to(() => SelectInterest(model: this));
    }
  }

  void findMatches() {
    Get.to(() => SelectInterest(model: this));
  }

  void chooseInterest() {
    if (selectedInterest.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectInterestsToContinue);
    }
    if (settingData?.appdata?.isDating == 0) {
      Get.to(() => AddPhotos(model: this));
    } else {
      Get.to(() => RelationshipGoal(model: this));
    }
  }

  void chooseRelationshipGoal() {
    if (selectedRelationshipGoals.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectYourRelationshipGoal);
    }
    Get.to(() => ChooseReligion(model: this));
  }

  void chooseReligion() {
    if (selectedReligion == null) {
      return CommonUI.snackBar(message: S.current.selectYourReligion);
    }
    Get.to(() => SelectLanguages(model: this));
  }

  void chooseLanguages() {
    if (selectedLanguages.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectYourLanguage);
    }
    Get.to(() => AddPhotos(model: this));
  }

  void addPhotos() {
    if (images.isEmpty) {
      return CommonUI.snackBar(message: S.current.addPhotos);
    }
    Get.to(() => YourProfileReady(model: this));
  }

  initImage() {
    for (Images element in (userData?.images ?? [])) {
      if (element.image != null) {
        images.add(Photo(element.id ?? -1, XFile(element.image!)));
      }
    }
  }

  void _initializeUserPreferences() {
    interestList =
        settingData?.interests?.where((e) => e.isDeleted == 0).toList() ?? [];
    List<String> savedInterest = userData?.interests?.split(',') ?? [];
    interestList.toList().forEach((element) {
      if (savedInterest.contains('${element.id}') &&
          !selectedInterest.any((e) => e.id == element.id)) {
        selectedInterest.add(element);
      }
    });

    relationshipGoals = settingData?.relationshipGoals
            ?.where((e) => e.isDeleted == 0)
            .toList() ??
        [];
    final goalIds = userData?.relationshipGoalIdsList ?? [];
    if (goalIds.isNotEmpty && selectedRelationshipGoals.isEmpty) {
      selectedRelationshipGoals = relationshipGoals
          .where((element) => goalIds.contains(element.id))
          .toList();
    }

    religions =
        settingData?.religions?.where((e) => e.isDeleted == 0).toList() ?? [];
    if (userData?.religionKey != null && selectedReligion == null) {
      selectedReligion = religions.firstWhereOrNull(
          (element) => element.title?.toLowerCase() == userData?.religionKey?.toLowerCase());
    }

    languages =
        settingData?.language?.where((e) => e.isDeleted == 0).toList() ?? [];
    final savedLangs = (userData?.languageKeys ?? '')
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    if (savedLangs.isNotEmpty && selectedLanguages.isEmpty) {
      selectedLanguages = languages
          .where((element) => savedLangs.contains(element.title?.removeEmojis.toLowerCase()))
          .toList();
    }
  }

  void tapFinalProfile() {
    bool isDating = settingData?.appdata?.isDating == 1;
    if (fullnameController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterFullName);
    }
    if (bioController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterBio);
    }

    final hasCountry = (selectCountryController.selectedCountry.value?.countryName != null &&
            selectCountryController.selectedCountry.value!.countryName.trim().isNotEmpty) ||
        (userData?.country != null && userData!.country!.trim().isNotEmpty);
    final hasState = (selectCountryController.selectedState.value?.name != null &&
            selectCountryController.selectedState.value!.name.trim().isNotEmpty) ||
        (userData?.state != null && userData!.state!.trim().isNotEmpty);
    final hasCity = (selectCountryController.selectedCity.value?.name != null &&
            selectCountryController.selectedCity.value!.name.trim().isNotEmpty) ||
        (userData?.city != null && userData!.city!.trim().isNotEmpty);

    if (!hasCountry) {
      CommonUI.snackBar(message: S.current.pleaseSelectCountry);
      Get.to(() => const CreateProfileScreen());
      return;
    }
    if (!hasState) {
      CommonUI.snackBar(message: S.current.pleaseSelectState);
      Get.to(() => const CreateProfileScreen());
      return;
    }
    if (!hasCity) {
      CommonUI.snackBar(message: S.current.pleaseSelectCity);
      Get.to(() => const CreateProfileScreen());
      return;
    }

    if (selectedInterest.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectInterestsToContinue);
    }
    if (isDating) {
      if (selectedRelationshipGoals.isEmpty) {
        return CommonUI.snackBar(message: S.current.selectYourRelationshipGoal);
      }
      if (selectedReligion == null) {
        return CommonUI.snackBar(message: S.current.selectYourReligion);
      }
      if (selectedLanguages.isEmpty) {
        return CommonUI.snackBar(message: S.current.selectYourLanguage);
      }
    }

    if (images.isEmpty) {
      return CommonUI.snackBar(message: S.current.addPhotos);
    }
    updateProfile();
  }

  void updateProfile() {
    List<XFile> image =
        images.where((element) => element.id == -1).map((e) => e.file).toList();

    final country = selectCountryController.selectedCountry.value?.countryName ??
        (userData?.country?.trim().isNotEmpty == true ? userData?.country?.trim() : 'Nigeria');
    final state = selectCountryController.selectedState.value?.name ??
        (userData?.state?.trim().isNotEmpty == true ? userData?.state?.trim() : 'Lagos');
    final city = selectCountryController.selectedCity.value?.name ??
        (userData?.city?.trim().isNotEmpty == true ? userData?.city?.trim() : 'Ikeja');

    CommonUI.lottieLoader();
    ApiProvider()
        .updateProfile(
            fullName: fullnameController.text.trim(),
            bio: bioController.text.trim(),
            about: aboutController.text.trim(),
            dob: selectedDob.dobFormat,
            gender: selectedGenderType.value,
            country: country,
            state: state,
            city: city,
            genderPreferred: selectedPreferredGender.value,
            ageMin: selectedAgeRange.start,
            ageMax: selectedAgeRange.end,
            distancePreference: selectedDistance,
            interest: selectedInterest.map((e) => '${e.id}').toList(),
            relationshipGoalId: selectedRelationshipGoals.map((e) => e.id).join(','),
            religionKey: selectedReligion?.title,
            languageKeys:
                selectedLanguages.map((e) => e.title?.removeEmojis).join(','),
            images: image,
            deleteImageIds: deletedImages.map((e) => '${e.id}').toList())
        .then((value) {
      Get.back();
      if (value.status == true) {
        if (value.data != null) {
          SessionManager.instance.setUser(value.data);
        }
        Get.offAll(() => const DashboardScreen());
      } else {
        CommonUI.snackBar(message: value.message ?? '');
      }
    });
  }
}

enum GenderType {
  male(1),
  female(2),
  other(3);

  final int value;

  const GenderType(this.value);

  String get title {
    switch (this) {
      case GenderType.male:
        return '👨 ${S.current.male}';
      case GenderType.female:
        return '👩‍🦰 ${S.current.female}';
      case GenderType.other:
        return S.current.other;
    }
  }

  static GenderType fromString(dynamic value) {
    int? intVal = value is int ? value : int.tryParse(value?.toString() ?? '');
    return GenderType.values.firstWhereOrNull((e) => e.value == intVal) ??
        GenderType.male;
  }
}

enum CreateProfileContinueTap {
  createProfile,
  findMatches,
  interest,
  relationGoal,
  religion,
  language,
  addPhoto,
  finalProfile
}

class Photo {
  int id;
  XFile file;

  Photo(this.id, this.file);
}
