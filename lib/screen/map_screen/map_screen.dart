import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/map_screen/map_screen_view_model.dart';
import 'package:orange_ui/screen/map_screen/widgets/map_top_bar_area.dart';
import 'package:orange_ui/screen/map_screen/widgets/user_pop_up.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/const_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';
import 'package:stacked/stacked.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MapScreenViewModel>.reactive(
      onViewModelReady: (model) => model.init(),
      viewModelBuilder: () => MapScreenViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: ColorRes.white,
          body: Stack(
            children: [
              // Offstage marker rendering
              Visibility(
                visible: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(children: model.widgets),
                ),
              ),

              // Main Map or List view
              if (model.isListView)
                _buildNearbyListView(context, model)
              else
                SizedBox(
                  height: Get.height,
                  width: Get.width,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    myLocationEnabled: false,
                    onMapCreated: (controller) {
                      model.mapController = controller;
                      model.onMapCreated(controller);
                      model.manager.setMapId(controller.mapId);
                    },
                    mapToolbarEnabled: false,
                    onCameraMove: model.manager.onCameraMove,
                    onCameraIdle: model.manager.updateMap,
                    markers: model.marker,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    indoorViewEnabled: true,
                    initialCameraPosition:
                        CameraPosition(target: model.center, zoom: 15.4746),
                  ),
                ),

              // Top Bar Area
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MapTopBarArea(
                  distanceList: model.distanceList,
                  selectedDistance: model.selectedDistance,
                  onDistanceChange: model.onDistanceChange,
                  isListView: model.isListView,
                  onToggleView: model.toggleView,
                  onMyLocationTap: model.moveToMyLocation,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNearbyListView(BuildContext context, MapScreenViewModel model) {
    return Container(
      color: ColorRes.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 65,
        left: 14,
        right: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${model.userList.length} nearby people within ${model.selectedDistance} km',
                  style: const TextStyle(
                    fontFamily: FontRes.bold,
                    fontSize: 14,
                    color: ColorRes.davyGrey,
                  ),
                ),
                InkWell(
                  onTap: model.toggleView,
                  child: const Row(
                    children: [
                      Icon(Icons.map_rounded, size: 16, color: ColorRes.themeColor),
                      SizedBox(width: 4),
                      Text(
                        'Map View',
                        style: TextStyle(
                          fontFamily: FontRes.semiBold,
                          fontSize: 13,
                          color: ColorRes.themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: model.userList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 54, color: ColorRes.grey20),
                        const SizedBox(height: 12),
                        Text(
                          'No users found within ${model.selectedDistance} km',
                          style: const TextStyle(
                            fontFamily: FontRes.bold,
                            fontSize: 15,
                            color: ColorRes.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try increasing the search distance above.',
                          style: TextStyle(
                            fontFamily: FontRes.regular,
                            fontSize: 13,
                            color: ColorRes.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: model.userList.length,
                    itemBuilder: (context, index) {
                      final user = model.userList[index];
                      return _buildUserGridCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGridCard(UserData user) {
    final image = user.profileImage;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Get.dialog(
          UserPopUp(user: user),
          barrierColor: Colors.black.withValues(alpha: 0.3),
        );
      },
      child: Container(
        decoration: ShapeDecoration(
          color: ColorRes.white,
          shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(
              SmoothRadius(cornerRadius: 16, cornerSmoothing: 1),
            ),
            side: BorderSide(color: ColorRes.grey5, width: 1),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image.isNotEmpty
                      ? CustomImage(
                          image: '${ConstRes.aImageBaseUrl}$image',
                          fit: BoxFit.cover,
                        )
                      : CommonUI.profileImagePlaceHolder(
                          name: CommonUI.fullName(user.fullname),
                          heightWidth: double.infinity,
                          borderRadius: 0,
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (user.isVerified == 2 || user.isVerified == 3)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: ColorRes.themeColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.fullname ?? 'User'}, ${user.age ?? ''}',
                    style: const TextStyle(
                      fontFamily: FontRes.bold,
                      fontSize: 14,
                      color: ColorRes.davyGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: ColorRes.themeColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          user.city ?? user.address ?? 'Nearby',
                          style: const TextStyle(
                            fontFamily: FontRes.medium,
                            fontSize: 11.5,
                            color: ColorRes.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
