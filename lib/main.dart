import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'blocs/app_navigator/app_navigator_bloc.dart';
import 'blocs/simple_bloc_observer.dart';
import 'main_app.dart';
import 'models/main_repository.dart';
import 'shared/common_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = SimpleBlocObserver();

  await Firebase.initializeApp();

  await Hive.initFlutter();
  Box _hiveBox = await Hive.openBox("appBox");

  // we get APIKEY and similar details from remoteconfig, safe and and reliable
  final RemoteConfig _remoteConfig = await RemoteConfig.instance;
  await _remoteConfig.fetch(expiration: const Duration(hours: 12));
  await _remoteConfig.activateFetched();
  // Enable developer mode to relax fetch throttling
  //_remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: !isPhysicalDevice));
  // optional: set defaults as backup option
  Map<String, dynamic> remoteConfigDefaults =
      await CommonUtils.parseJsonFromAssets('assets/config/remoteconfig_defaults.json');
  _remoteConfig.setDefaults(remoteConfigDefaults);

  final MainRepository _mainRepository =
      MainRepository(hiveBox: _hiveBox, remoteConfig: _remoteConfig);

  final String devicePlatform = await CommonUtils.getDevicePlatform();
  final bool isPhysicalDevice = await CommonUtils.isPhysicalDevice(devicePlatform: devicePlatform);
  _mainRepository.hiveStore.save("DEVICEPLATFORM", devicePlatform);
  _mainRepository.hiveStore.save("IS_PHYSICAL_DEVICE", isPhysicalDevice);

  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(isPhysicalDevice);
  // Pass all uncaught errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    // dumps errors to console
    FlutterError.dumpErrorToConsole(errorDetails);
  };

  runApp(MultiBlocProvider(providers: [
    BlocProvider<AppNavigatorBloc>(
        lazy: false, create: (context) => AppNavigatorBloc(mainRepository: _mainRepository)),
  ], child: MainApp()));
}
