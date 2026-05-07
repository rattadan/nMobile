import 'package:nchat_mobile/common/settings.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/components/layout/expansion_layout.dart';
import 'package:nchat_mobile/helpers/error.dart';
import 'package:nchat_mobile/helpers/file.dart';
import 'package:nchat_mobile/helpers/media_picker.dart';
import 'package:nchat_mobile/utils/logger.dart';
import 'package:nchat_mobile/utils/path.dart';

class ChatBottomMenu extends StatelessWidget {
  final String? target;
  final bool show;
  final Function(List<Map<String, dynamic>> result)? onPicked;

  ChatBottomMenu({
    this.target,
    this.show = false,
    this.onPicked,
  });

  _pickImages({required ImageSource source}) async {
    List<Map<String, dynamic>> results;
    if (source == ImageSource.camera) {
      // no video so no encode
      String savePath = await Path.getRandomFile(
          clientCommon.getPublicKey(), DirType.chat,
          subPath: target, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
      application.inSystemSelecting = true;
      Map<String, dynamic>? result = await MediaPicker.takeImage(savePath);
      application.inSystemSelecting = false;
      if (result == null || result.isEmpty) return;
      results = []..add(result);
    } else {
      int maxNum = 9;
      List<String> savePaths = [];
      for (var i = 0; i < maxNum; i++) {
        String subPath = Uri.encodeComponent(target ?? "");
        if (subPath != target) subPath = "common"; // FUTURE:GG encode
        String savePath = await Path.getRandomFile(
            clientCommon.getPublicKey(), DirType.chat,
            subPath: subPath, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
        savePaths.add(savePath);
      }
      application.inSystemSelecting = true;
      results = await MediaPicker.pickCommons(savePaths,
          maxSize: Settings.sizeIpfsMax);
      application.inSystemSelecting = false;
    }
    if (results.isEmpty) return;
    for (var i = 0; i < results.length; i++) {
      Map<String, dynamic> map = results[i];
      String? original = map["path"]?.toString();
      int? size = int.tryParse(map["size"]?.toString() ?? "");
      String? mimeType = map["mimeType"]?.toString();
      if ((original != null) &&
          original.isNotEmpty &&
          (mimeType != null) &&
          mimeType.isNotEmpty) {
        if (mimeType.contains("video") == true) {
          String savePath = await Path.getRandomFile(
              clientCommon.getPublicKey(), DirType.chat,
              subPath: target, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
          Map<String, dynamic>? res =
              await MediaPicker.getVideoThumbnail(original, savePath);
          if (res != null && res.isNotEmpty) {
            results[i]["thumbnailPath"] = res["path"];
            results[i]["thumbnailSize"] = res["size"];
          }
        } else if ((mimeType.contains("image") == true) &&
            ((size ?? 0) > Settings.piecesMaxSize)) {
          String savePath = await Path.getRandomFile(
              clientCommon.getPublicKey(), DirType.chat,
              subPath: target, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
          File? thumbnail = await MediaPicker.compressImageBySize(
              File(original),
              savePath: savePath,
              maxSize: Settings.sizeThumbnailMax,
              bestSize: Settings.sizeThumbnailBest,
              force: true);
          if (thumbnail != null) {
            results[i]["thumbnailPath"] = thumbnail.absolute.path;
            results[i]["thumbnailSize"] = thumbnail.lengthSync();
          }
        }
      }
    }
    if (results.isEmpty) return;
    onPicked?.call(results);
  }

  _pickFiles({int? maxSize}) async {
    FilePickerResult? result;
    application.inSystemSelecting = true;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowCompression: true,
      );
    } catch (e, st) {
      handleError(e, st);
    }
    application.inSystemSelecting = false;
    if (result == null || result.files.isEmpty) return;
    List<Map<String, dynamic>> results = [];
    for (var i = 0; i < result.files.length; i++) {
      PlatformFile picked = result.files[i];
      String? path = picked.path;
      String name = picked.name;
      int? size = picked.size;
      String? mimeType = picked.extension;
      if (path == null || path.isEmpty) continue;
      Map<String, dynamic> map = {
        "path": path,
        "name": name,
        "size": size,
        "mimeType": mimeType,
        "thumbnailPath": null,
        "thumbnailSize": null,
      };
      if ((mimeType != null) && mimeType.isNotEmpty) {
        if (mimeType.contains("video") == true) {
          String thumbnailPath = await Path.getRandomFile(
              clientCommon.getPublicKey(), DirType.chat,
              subPath: target, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
          Map<String, dynamic>? res =
              await MediaPicker.getVideoThumbnail(path, thumbnailPath);
          if (res != null && res.isNotEmpty) {
            map["thumbnailPath"] = res["path"];
            map["thumbnailSize"] = res["size"];
          }
        } else if ((mimeType.contains("image") == true) &&
            (size > Settings.piecesMaxSize)) {
          String thumbnailPath = await Path.getRandomFile(
              clientCommon.getPublicKey(), DirType.chat,
              subPath: target, fileExt: FileHelper.DEFAULT_IMAGE_EXT);
          File? thumbnail = await MediaPicker.compressImageBySize(File(path),
              savePath: thumbnailPath,
              maxSize: Settings.sizeThumbnailMax,
              bestSize: Settings.sizeThumbnailBest,
              force: true);
          if (thumbnail != null) {
            map["thumbnailPath"] = thumbnail.absolute.path;
            map["thumbnailSize"] = thumbnail.lengthSync();
          }
        }
      }
      results.add(map);
    }
    logger.i("BottomMenu - _pickFiles - results:$results");
    if (results.isEmpty) return;
    onPicked?.call(results);
  }

  void _showMediaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: application.theme.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: application.theme.fontColor4.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Share Media',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: application.theme.fontColor1,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.xmark,
                        color: application.theme.fontColor3,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMediaOption(
                            context,
                            icon: CupertinoIcons.camera_fill,
                            title: 'Camera',
                            subtitle: 'Take photo or video',
                            color: Color(0xFF007AFF),
                            onTap: () {
                              Navigator.of(context).pop();
                              _pickImages(source: ImageSource.camera);
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildMediaOption(
                            context,
                            icon: CupertinoIcons.photo_fill,
                            title: 'Gallery',
                            subtitle: 'Choose from photos',
                            color: Color(0xFF34C759),
                            onTap: () {
                              Navigator.of(context).pop();
                              _pickImages(source: ImageSource.gallery);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMediaOption(
                            context,
                            icon: CupertinoIcons.folder_fill,
                            title: 'Files',
                            subtitle: 'Choose documents',
                            color: Color(0xFFFF9500),
                            onTap: () {
                              Navigator.of(context).pop();
                              _pickFiles(maxSize: Settings.sizeIpfsMax);
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: application.theme.fontColor1,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: application.theme.fontColor3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionLayout(
      isExpanded: show,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: application.theme.backgroundColor2),
          ),
        ),
        child: GestureDetector(
          onPanUpdate: (details) {
            // Detect upward swipe
            if (details.delta.dy < -10) {
              _showMediaBottomSheet(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Draggable handle/rim
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: application.theme.fontColor4.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Subtle hint text
                Text(
                  'Swipe up to attach media',
                  style: TextStyle(
                    fontSize: 12,
                    color: application.theme.fontColor4.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
