import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDdPtGVH4g8bv1i-B-xu3LtD9SVpbIb98',
    appId: '1:479709829805:android:c97e4faf7ea5a308ee0424',
    messagingSenderId: '479709829805',
    projectId: 'cleanlyflow',
    databaseURL: 'https://cleanlyflow-default-rtdb.firebaseio.com/',
    storageBucket: 'cleanlyflow.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBawM1qvPFenrWgJzaAC3eO9-nvsKoyUdM',
    appId: '1:479709829805:ios:f4ab880e8c3d9447ee0424',
    messagingSenderId: '479709829805',
    projectId: 'cleanlyflow',
    databaseURL: 'https://cleanlyflow-default-rtdb.firebaseio.com/',
    storageBucket: 'cleanlyflow.firebasestorage.app',
    iosBundleId: 'com.cleanly.task.app2026',
  );
}
