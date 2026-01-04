import 'package:package_info_plus/package_info_plus.dart';

Future<String> getAppVersionString() async {
  final info = await PackageInfo.fromPlatform();
  // info.version = human version (e.g. 1.2.3)
  // info.buildNumber = build code (e.g. 42)
  return '${info.version}+${info.buildNumber}';
}

Future<String> getPackageName() async {
  final info = await PackageInfo.fromPlatform();
  return info.packageName; // Android: applicationId, iOS: bundle id
}