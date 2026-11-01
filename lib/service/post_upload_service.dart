import 'dart:async';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/social/post/add_comment.dart';
import 'package:orange_ui/model/social/post/add_post.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/urls.dart';

class PostUploadService extends GetxService {
  static PostUploadService get instance => Get.find<PostUploadService>();

  final RxBool isUploading = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxString statusText = ''.obs;
  final Rx<Post?> newlyCreatedPost = Rx<Post?>(null);
  final Rx<XFile?> previewThumbnail = Rx<XFile?>(null);

  Timer? _progressTimer;

  static void init() {
    if (!Get.isRegistered<PostUploadService>()) {
      Get.put(PostUploadService(), permanent: true);
    }
  }

  void startUpload({
    required String description,
    required List<String> hashtags,
    required List<int> selectedInterests,
    required int contentType,
    required List<XFile> imagesFile,
    XFile? thumbnailFile,
  }) {
    isUploading.value = true;
    progress.value = 0.15;
    statusText.value = 'Sharing post...';
    previewThumbnail.value = thumbnailFile ?? (imagesFile.isNotEmpty ? imagesFile.first : null);

    // Simulate steady progress while network request runs
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (progress.value < 0.85) {
        progress.value = (progress.value + 0.08).clamp(0.0, 0.85);
      }
    });

    List<String> removeHasTag = [];
    for (var element in hashtags) {
      removeHasTag.add(element.replaceAll('#', ''));
    }

    Map<String, List<XFile?>>? filesMap = {};
    if (imagesFile.isNotEmpty) {
      if (contentType == 1 && thumbnailFile != null) {
        filesMap[Urls.aThumbnail] = [thumbnailFile];
      }
      filesMap[Urls.aContents] = imagesFile;
    }

    ApiProvider().multiPartCallApi(
      url: Urls.aAddPost,
      completion: (response) {
        _progressTimer?.cancel();
        AddPost postData = AddPost.fromJson(response);
        if (postData.status == true && postData.data != null) {
          progress.value = 1.0;
          statusText.value = 'Posted! ✓';
          newlyCreatedPost.value = postData.data;

          Future.delayed(const Duration(milliseconds: 1600), () {
            isUploading.value = false;
            statusText.value = '';
            previewThumbnail.value = null;
            newlyCreatedPost.value = null;
          });
        } else {
          isUploading.value = false;
          statusText.value = '';
          previewThumbnail.value = null;
          CommonUI.snackBar(message: postData.message ?? 'Upload failed');
        }
      },
      param: {
        Urls.userId: SessionManager.instance.getUserID().toString(),
        if (description.isNotEmpty) Urls.aDescription: description,
        if (removeHasTag.isNotEmpty) Urls.aHashtags: removeHasTag.join(','),
        if (selectedInterests.isNotEmpty)
          Urls.aInterestIds: selectedInterests.join(','),
        Urls.aContentType: imagesFile.isEmpty ? 2 : contentType,
      },
      filesMap: filesMap,
    );
  }
}
