import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class SavedProfilesScreenViewModel extends BaseViewModel {
  List<UserData> userData = [];
  bool isLoading = true;

  void init() {
    fetchSavedProfiles();
  }

  void fetchSavedProfiles() async {
    isLoading = true;
    ApiProvider().fetchSavedProfiles().then((value) {
      isLoading = false;
      userData = value.data ?? [];
      notifyListeners();
    });
  }

  onSavedClick(UserData user) async {
    final bool previousState = user.isSaved;
    final bool newState = !previousState;
    user.isSaved = newState;
    if (!newState) {
      userData.removeWhere((element) => element.id == user.id);
    }
    notifyListeners();
    await ApiProvider().updateSaveProfile(user.id, setSaved: newState);
  }

  void onSavedCardBack() {
    List<String> savedIds =
        (SessionManager.instance.getUser()?.savedProfile ?? '').split(',');
    userData.removeWhere((element) => !savedIds.contains('${element.id}'));
    notifyListeners();
  }
}
