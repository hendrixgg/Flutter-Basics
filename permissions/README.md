# permissions

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Permission Declarations
look for comment in files:
- Android: see file "./android/app/src/main/AndroidManifest.xml"
- IOS: see file "./ios/Runner/Info.plist"

## Running on IOS
To run on IOS you need to alter your Podfile ("ios/Podfile") see the link: https://pub.dev/packages/permission_handler#:~:text=all%20possible%20permissions.-,iOS,-Add%20permission%20to for more information.

For this application, all you have to do is the following:

Based on [this](https://youtu.be/SghsImxwGxE?si=4lWBcbCvdrjou-x1&t=172) youtube video go to file "ios/Podfile" and overwrite the following code:
```
post_install do |installer|
    installer.pods_project.targets.each do |target|
        flutter_additional_ios+build_settings(target)
    end
end
```
with this instead:
```
post_install do |installer|
    installer.pods_project.targets.each do |target|
        flutter_additional_ios_build_settings(target)
        target.build_configuration.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '_12.3'

            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
                '$(inherited)',
                ## dart: PermissionGroup.photos
                'PERMISSION_PHOTOS=1',
            ]
            end
    end
end
```