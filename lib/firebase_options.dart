// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbRmJ2fvZP-hqc9lEv_HPMRjEnkMquXZ8',
    appId: '1:909258711043:web:9773c7177f3c45defeee36',
    messagingSenderId: '909258711043',
    projectId: 'active-circle-prod',
    authDomain: 'active-circle-prod.firebaseapp.com',
    storageBucket: 'active-circle-prod.appspot.com',
    measurementId: 'G-JMFX0TMQC7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAnKBibBdgDquKbnFugoTLg9Gn33tc3DI',
    appId: '1:909258711043:android:6110b72ba2d2d137feee36',
    messagingSenderId: '909258711043',
    projectId: 'active-circle-prod',
    storageBucket: 'active-circle-prod.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyASeIc60NxqI0WTQNf-NTFWWAhEHgtZa54',
    appId: '1:909258711043:ios:51eee049ad3d39dafeee36',
    messagingSenderId: '909258711043',
    projectId: 'active-circle-prod',
    storageBucket: 'active-circle-prod.appspot.com',
    iosBundleId: 'com.example.activeCircle',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyASeIc60NxqI0WTQNf-NTFWWAhEHgtZa54',
    appId: '1:909258711043:ios:51eee049ad3d39dafeee36',
    messagingSenderId: '909258711043',
    projectId: 'active-circle-prod',
    storageBucket: 'active-circle-prod.appspot.com',
    iosBundleId: 'com.example.activeCircle',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAbRmJ2fvZP-hqc9lEv_HPMRjEnkMquXZ8',
    appId: '1:909258711043:web:c1ab80f3f0cd40f4feee36',
    messagingSenderId: '909258711043',
    projectId: 'active-circle-prod',
    authDomain: 'active-circle-prod.firebaseapp.com',
    storageBucket: 'active-circle-prod.appspot.com',
    measurementId: 'G-B1FB6CFJMS',
  );
}
