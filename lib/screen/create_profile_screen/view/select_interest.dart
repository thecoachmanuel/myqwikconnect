import 'package:flutter/material.dart';
import 'package:orange_ui/common/button/custom_text_button.dart';
import 'package:orange_ui/common/login_setup_view.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:orange_ui/screen/create_profile_screen/widget/border_text_card.dart';
import 'package:orange_ui/screen/create_profile_screen/widget/error_text_widget.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class SelectInterest extends StatelessWidget {
  final UserData? userData;
  final CreateProfileScreenViewModel model;

  const SelectInterest({super.key, this.userData, required this.model});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateProfileScreenViewModel>.reactive(
      viewModelBuilder: () => model,
      onViewModelReady: (viewModel) {
        viewModel.ensureSettingsLoaded();
      },
      disposeViewModel: false,
      builder: (context, viewModel, child) => LoginSetupView(
        title: S.of(context).discoverLikemindedPeople,
        description: 'Select your interests, it helps with matching.',
        child: Column(
          children: [
            Expanded(
              child: viewModel.isLoadingSettings && viewModel.interestList.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: ColorRes.themeColor),
                    )
                  : viewModel.interestList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ErrorTextWidget(S
                                  .of(context)
                                  .pleaseAddInterestsInTheAdminPanelToContinue),
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
                          child: WrapListTiles<Interests>(
                            onTap: viewModel.onSelectInterest,
                            getText: (p0) => p0.title ?? '',
                            items: viewModel.interestList,
                            selectedItems: viewModel.selectedInterest,
                            isSelected: (item) => viewModel.selectedInterest
                                .any((e) => e.id == item.id || (e.title != null && e.title == item.title)),
                          ),
                        ),
            ),
            CustomTextButton(
              onTap: () =>
                  viewModel.onContinueTap(CreateProfileContinueTap.interest),
            )
          ],
        ),
      ),
    );
  }
}

class WrapListTiles<T> extends StatelessWidget {
  final List<T> items;
  final List<T?> selectedItems;
  final String Function(T) getText;
  final Function(T) onTap;
  final bool Function(T item)? isSelected;

  const WrapListTiles({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.getText,
    required this.onTap,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        items.length,
        (index) {
          final item = items[index];
          final bool selected = isSelected != null
              ? isSelected!(item)
              : selectedItems.contains(item);
          return FittedBox(
            child: BorderTextCard(
              text: getText(item),
              onTap: () => onTap(item),
              isSelected: selected,
              padding: const EdgeInsets.only(left: 12, right: 12),
            ),
          );
        },
      ),
    );
  }
}
