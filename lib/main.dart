import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:livocal/features/auth/data/repositories/auth_repository.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/storage_paths.dart';
import 'features/auth/views/welcome.dart';

import 'features/home/views/base.dart';
import 'package:livocal/shared/widgets/app_auth_guard.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'firebase_options.dart';

import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e, st) {
    debugPrint("Firebase init error: $e\n$st");
  }

  try {
    await SharedPref.init();
    await GeminiLiveTranslator.initSecureStorage();
  } catch (e, st) {
    debugPrint("SharedPref / SecureStorage init error: $e\n$st");
  }

  try {
    await IsarDb.init();
    await IsarDb.purgeDisappearingMessages();
  } catch (e, st) {
    debugPrint("IsarDb init error: $e\n$st");
  }

  try {
    await DeviceStorage.init();
  } catch (e, st) {
    debugPrint("DeviceStorage init error: $e\n$st");
  }

  ErrorWidget.builder = (details) => CustomErrorWidget(details: details);
  return runApp(
    const ProviderScope(
      child: Livocal(),
    ),
  );
}

class Livocal extends ConsumerWidget {
  const Livocal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      title: "Livocal",
      initialRoute: '/',
      theme: ref.read(lightThemeProvider),
      darkTheme: ref.read(darkThemeProvider),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
        Locale('hi'),
        Locale('ar'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<auth.User?>(
        stream: ref.read(authRepositoryProvider).auth.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          final firebaseUser = snapshot.data;
          if (firebaseUser == null) {
            return const WelcomePage();
          }
          final user = getCurrentUser();
          if (user != null && user.id == firebaseUser.uid) {
            return AppAuthGuard(
              child: HomePage(user: user),
            );
          }
          return const WelcomePage();
        },
      ),
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const CustomErrorWidget({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 25,
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(150),
                  color: colorTheme.appBarColor,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 50,
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorTheme.appBarColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      child: ListView(
                        children: [
                          const SizedBox(
                            height: 20.0,
                          ),
                          Text(
                            'OOPS!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              color: Colors.red[400],
                            ),
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          Text(
                            details.toString(),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: colorTheme.blueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
