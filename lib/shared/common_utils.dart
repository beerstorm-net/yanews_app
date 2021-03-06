import 'dart:convert';

import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class CommonUtils {
  // FIXME: isDebug is a manual switch, but it must come from isPhysicalDevice
  static final isDebug = true;
  static final Logger logger = Logger(
    level: isDebug ? Level.debug : Level.warning,
    printer: PrettyPrinter(
        methodCount: 2, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 120, // width of the output
        colors: true, // Colorful log messages
        printEmojis: false, // Print an emoji for each log message
        printTime: true // Should each log print contain a timestamp
        ),
  );

  static String nullSafe(String source) {
    return (source == null || source.isEmpty || source == "null") ? "" : source;
  }

  static String nullSafeSnap(dynamic source) {
    return source != null ? nullSafe(source as String) : "";
  }

  static String generateUuid() {
    var uuid = Uuid();
    return uuid.v5(Uuid.NAMESPACE_URL, 'beerstorm.net');
  }

  static String getFormattedDate({DateTime date}) {
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(date ?? DateTime.now());
  }

  static humanizeDateText(String dateAt) {
    Jiffy jiffy = Jiffy(dateAt);
    if (jiffy.diff(DateTime.now(), Units.DAY) > -7) {
      return jiffy.fromNow();
    } else {
      return jiffy.format("EEEE, dd MMMM yyyy"); // man, 22 mar 2020
    }
  }

  static launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: true,
        enableJavaScript: true,
        enableDomStorage: true,
        //headers: <String, String>{'source': 'beerstorm.net'}
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<Map<String, dynamic>> parseJsonFromAssets(String filePath) async {
    return rootBundle.loadString(filePath).then((jsonStr) => jsonDecode(jsonStr));
  }

  static String appendParamToUrl(String reqUrl, String paramKey, String paramVal) {
    if (nullSafe(paramKey).isNotEmpty && nullSafe(paramVal).isNotEmpty) {
      reqUrl += (reqUrl.contains("?") ? "&" : "?") + paramKey.trim() + "=" + paramVal.trim();
    }
    return reqUrl;
  }

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  static Future<bool> isPhysicalDevice({String devicePlatform}) async {
    if (nullSafe(devicePlatform).isEmpty) {
      devicePlatform = await getDevicePlatform();
    }
    if (devicePlatform?.toLowerCase() == "ios") {
      IosDeviceInfo iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      return iosDeviceInfo.isPhysicalDevice;
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      return androidDeviceInfo.isPhysicalDevice;
    }
  }

  static Future<String> getDevicePlatform() async {
    try {
      IosDeviceInfo iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      if (iosDeviceInfo != null) {
        CommonUtils.logger.d('iOS device!');
        return "ios";
      }
    } catch (_) {
      CommonUtils.logger.d('ANDROID device!');
      return "android";
    }
    return "android"; // default
  }
}
