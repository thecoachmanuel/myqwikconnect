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

class ChooseReligion extends StatelessWidget {
  final UserData? userData;
  final CreateProfileScreenViewModel model;

  const ChooseReligion({super.key, this.userData, required this.model});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateProfileScreenViewModel>.reactive(
      viewModelBuilder: () => model,
      onViewModelReady: (viewModel) {
        viewModel.ensureSettingsLoaded();
      },
      disposeViewModel: false,
      builder: (context, viewModel, child) => LoginSetupView(
        title: S.of(context).findReligion,
        description: 'This helps others to understand what you believe..',
        child: Column(
          children: [
            Expanded(
              child: viewModel.isLoadingSettings && viewModel.religions.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: ColorRes.themeColor))
                  : viewModel.religions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ErrorTextWidget(S
                                  .of(context)
                                  .pleaseAddReligionInTheAdminPanelToContinue),
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
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              viewModel.religions.length,
                              (index) {
                                final religion = viewModel.religions[index];
                                bool isSelected = viewModel.selectedReligion?.id == religion.id ||
                                    (viewModel.selectedReligion?.title != null &&
                                     viewModel.selectedReligion?.title == religion.title);

                                return FittedBox(
                                  child: BorderTextCard(
                                    text: religion.title ?? '',
                                    onTap: () => viewModel.onSelectReligion(religion),
                                    isSelected: isSelected,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
            CustomTextButton(
              onTap: () =>
                  viewModel.onContinueTap(CreateProfileContinueTap.religion),
            )
          ],
        ),
      ),
    );
  }
}
