import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permissions/image_model.dart';
import 'package:provider/provider.dart';

/// Widget to that prompts the user to select an image to display.
///
/// This widget will ask for permission to access photos/files if the user has not granted permission.
class ImageScreen extends StatefulWidget {
  const ImageScreen({Key? key}) : super(key: key);

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

// WidgetsBindingObserver is used to listen to the app's lifecycle events. In this case, we are listening to when the app is resumed.
class _ImageScreenState extends State<ImageScreen> with WidgetsBindingObserver {
  /// Stores the image and manages permission requests and the state of the app.
  late final ImageModel _model;

  /// Whether or not we should detect if permissions has been granted when the app is resumed.
  bool _detectPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _model = ImageModel();
  }

  /// Remove the observer when this widget is disposed so we can track if the app has been opened/closed.
  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// This assumes that when the app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the app is resumed (app is returning to the foreground), check if the user has granted permission to access photos/files.
    if (state == AppLifecycleState.resumed && _detectPermission) {
      _detectPermission = false;
      _model.requestPermission();
    }
    // If the app is paused (app is going to the background), set the flag to detect permission to true so that we check for permission when the app is resumed.
    else if (state == AppLifecycleState.paused &&
        _model.imageSection == ImageSection.noStoragePermissionPermanent) {
      _detectPermission = true;
    }
  }

  /// Responsible for requesting the permission
  /// If the permission is granted, then this will call [_model.pickFile] to pick a file.
  Future<void> _requestPermissionAndPickFile() async {
    if (!(await _model.requestPermission())) {
      return;
    }
    try {
      await _model.pickFile();
    } on Exception catch (e) {
      debugPrint('Error picking file: $e');
      // Show a snackbar if the current context is still mounted.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while picking an image.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Consumer<ImageModel>(builder: (context, model, child) {
        Widget widget;

        switch (model.imageSection) {
          case ImageSection.noStoragePermission:
            widget = _ImagePermissions(
              isPermanentlyDenied: false,
              onPressed: _requestPermissionAndPickFile,
            );
            break;
          case ImageSection.noStoragePermissionPermanent:
            widget = _ImagePermissions(
              isPermanentlyDenied: true,
              onPressed: _requestPermissionAndPickFile,
            );
            break;
          case ImageSection.browseFiles:
            widget = _PickFile(
              onPressed: _requestPermissionAndPickFile,
            );
            break;
          case ImageSection.imageLoaded:
            widget = _ImageLoaded(
              file: model.file!,
              onPressed: _requestPermissionAndPickFile,
            );
            break;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Handle Permissions'),
          ),
          body: widget,
        );
      }),
    );
  }
}

/// Widget to display when the user has not granted permission to access photos/files.
class _ImagePermissions extends StatelessWidget {
  /// If the user has permanently denied the permission, the user needs to go to the system settings to grant the permission.
  final bool isPermanentlyDenied;

  /// Callback to be called when the user presses the button to and they have not permanently denied the permission.
  final VoidCallback onPressed;

  /// Padding for the containers in this widget.
  final containerPadding = const EdgeInsets.only(
    left: 16,
    top: 24,
    right: 16,
  );

  const _ImagePermissions({
    Key? key,
    required this.isPermanentlyDenied,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: containerPadding,
          child: Text(
            isPermanentlyDenied
                ? 'Please go to settings and grant permission to access photos.'
                : 'Please grant permission to access photos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Container(
          padding: containerPadding,
          child: const Text(
            'This app needs your permission to access photos to display them locally in the app.',
            textAlign: TextAlign.center,
          ),
        ),
        if (isPermanentlyDenied)
          Container(
            padding: containerPadding,
            child: const Text(
              'You need to grant permission from the system settings.',
              textAlign: TextAlign.center,
            ),
          ),
        Container(
          padding: containerPadding,
          child: ElevatedButton(
            onPressed: () =>
                isPermanentlyDenied ? openAppSettings() : onPressed(),
            child: Text(isPermanentlyDenied ? 'Open Settings' : 'Allow Access'),
          ),
        ),
      ]),
    );
  }
}

/// Widget containing a button to pick a file.
/// This widget will be used when the user has granted permission to access photos/files.
class _PickFile extends StatelessWidget {
  final VoidCallback onPressed;

  const _PickFile({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Pick File'),
      ),
    );
  }
}

/// Widget to display the image selected by the user.
/// This widget will be shown when the user has:
/// - granted permission to access photos/files
/// - picked a file
/// - the file is a vaild image
class _ImageLoaded extends StatelessWidget {
  final File file;
  final VoidCallback onPressed;

  const _ImageLoaded({Key? key, required this.file, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        onPressed: onPressed,
        child: SizedBox(
          width: 196.0,
          height: 196.0,
          child: ClipOval(
            child: Image.file(
              file,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ),
    );
  }
}
