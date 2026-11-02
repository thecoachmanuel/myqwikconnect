import 'package:flutter/material.dart';
import 'package:orange_ui/common/button/custom_text_button.dart';
import 'package:orange_ui/common/login_setup_view.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:orange_ui/screen/create_profile_screen/widget/border_text_card.dart';
import 'package:orange_ui/screen/create_profile_screen/widget/error_text_widget.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class SelectLanguages extends StatelessWidget {
  final UserData? userData;
  final CreateProfileScreenViewModel model;

  const SelectLanguages({super.key, this.userData, required this.model});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateProfileScreenViewModel>.reactive(
      viewModelBuilder: () => model,
      onViewModelReady: (viewModel) {
        viewModel.ensureSettingsLoaded();
      },
      disposeViewModel: false,
      builder: (context, viewModel, child) => LoginSetupView(
        title: S.of(context).selectLanguages,
        description: 'Select languages you are familiar with',
        child: Column(
          children: [
            Expanded(
              child: viewModel.isLoadingSettings && viewModel.languages.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: ColorRes.themeColor))
                  : viewModel.languages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ErrorTextWidget(S
                                  .of(context)
                                  .pleaseAddLanguagesInTheAdminPanelToContinue),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => viewModel.loadSettingsData(force: true),
                                icon: const Icon(Icons.refresh, color: ColorRes.themeColor),
                                label: const Text('Retry',
                                    style: TextStyle(
                                        fontFamily: FontRes.semiBold,
                                        color: ColorRes.themeColor)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: ColorRes.themeColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: viewModel.languages.length,
                          itemBuilder: (context, index) {
                            final lang = viewModel.languages[index];
                            bool isSelected = viewModel.selectedLanguages.any(
                                (element) =>
                                    element.id == lang.id ||
                                    (element.title != null && element.title?.trim().toLowerCase() == lang.title?.trim().toLowerCase()));
                            return BorderTextCard(
                              text: lang.title ?? '',
                              onTap: () => viewModel.onSelectLanguages(lang),
                              isSelected: isSelected,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              isCheckBtnVisible: true,
                              margin: const EdgeInsets.only(bottom: 5),
                            );
                          }),
            ),
            CustomTextButton(
              onTap: () =>
                  viewModel.onContinueTap(CreateProfileContinueTap.language),
            )
          ],
        ),
      ),
    );
  }
}
