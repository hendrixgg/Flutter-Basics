import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Enum for the different 'states' or 'sections' of the app
enum ImageSection {
  noStoragePermission,
  noStoragePermissionPermanent,
  browseFiles,
  imageLoaded,
}

class ImageModel extends ChangeNotifier {
  ImageSection _imageSection = ImageSection.browseFiles;

  ImageSection get imageSection => _imageSection;

  /// Notifies all listeners that the imageSection has changed.
  set imageSection(ImageSection value) {
    if (value != _imageSection) {
      _imageSection = value;
      notifyListeners();
    }
  }

  File? _file;

  File? get file => _file;

  /// Notifies all listeners that the file has changed.
  set file(File? value) {
    if (value != _file) {
      _file = value;
      notifyListeners();
    }
  }

  /// Request permissions to access photos on the device.
  ///
  /// This will update the [imageSection] to [ImageSection.noStoragePermission] or [ImageSection.noStoragePermissionPermanent] if the permission is denied.
  ///
  /// @return true if permission is granted, false otherwise.
  Future<bool> requestPermission() async {
    PermissionStatus result;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        result = await Permission.storage.request();
      } else {
        result = await Permission.photos.request();
      }
    } else if (Platform.isIOS) {
      result = await Permission.photos.request();
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    // If permission is granted, return true
    if (result.isGranted) {
      return true;
    }
    // On ios, if permission is denied once, it is permanently denied
    if (Platform.isIOS || result.isPermanentlyDenied) {
      imageSection = ImageSection.noStoragePermissionPermanent;
    }
    // result.isDenied && Platform.isAndroid
    else {
      // On android, if permission is denied once, it is not permanently denied, but the next time the permission request is shown, the user will have the option to permanently deny it.
      imageSection = ImageSection.noStoragePermission;
    }
    return false;
  }

  /// This function should only run if the user has already granted permission to access photos/files.
  /// Calls the [FilePicker] to pick an image file, opens a device-specific file picker.
  /// If a file is picked, the [imageSection] is updated to [ImageSection.imageLoaded].
  /// If no file is picked, the [imageSection] is updated to [ImageSection.browseFiles].
  Future<void> pickFile() async {
    assert(imageSection != ImageSection.noStoragePermission &&
        imageSection != ImageSection.noStoragePermissionPermanent);
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    // if a valid file was selected successfuly, update the imageSection to imageLoaded.
    if (result != null &&
        result.files.isNotEmpty &&
        result.files.single.path != null) {
      debugPrint('File picked: ${result.files.single.path}');
      file = File(result.files.single.path!);
      imageSection = ImageSection.imageLoaded;
    }
    // Since we assumed that permission has already been granted to access photos/files, if no file is picked, then the user must have cancelled the file picker and we should update the imageSection to browseFiles.
    else if (imageSection != ImageSection.imageLoaded) {
      imageSection = ImageSection.browseFiles;
    }
  }
}
