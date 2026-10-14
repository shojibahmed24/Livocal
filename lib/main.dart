import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_clone/features/auth/data/repositories/auth_repository.dart';
import 'package:whatsapp_clone/shared/repositories/isar_db.dart';
import 'package:whatsapp_clone/shared/utils/abc.dart';
import 'package:whatsapp_clone/shared/utils/shared_pref.dart';
import 'package:whatsapp_clone/shared/utils/storage_paths.dart';
import 'features/auth/views/welcome.dart';

import 'features/home/views/base.dart';
import 'firebase_options.dart';

import 'package:whatsapp_clone/features/calls/services/gemini_live_translator.dart';
import 'package:whatsapp_clone/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
    return MaterialApp(
      title: "Livocal",
      initialRoute: '/',
      theme: ref.read(lightThemeProvider),
      darkTheme: ref.read(darkThemeProvider),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<auth.User?>(
        stream: ref.read(authRepositoryProvider).auth.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          final user = getCurrentUser();
          if (user != null) {
            return HomePage(user: user);
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
