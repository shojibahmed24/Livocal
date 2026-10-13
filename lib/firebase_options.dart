// File generated from android/app/google-services.json and ios/Runner/GoogleService-Info.plist
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwlQsJhaQF30xjFV6xgm84k34kOz0Rj_0',
    appId: '1:729373303752:android:11ce0d04ae5a01089856fd',
    messagingSenderId: '729373303752',
    projectId: 'livocal24',
    storageBucket: 'livocal24.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxaUXWZs4Fkfo2IGbneHDSDGDrshMLYSU',
    appId: '1:1007219918966:ios:073839fdb12829046bf757',
    messagingSenderId: '1007219918966',
    projectId: 'whatsapp-clone-7a78c',
    storageBucket: 'whatsapp-clone-7a78c.appspot.com',
    iosBundleId: 'com.tauseef.whatsappclone',
  );
}
