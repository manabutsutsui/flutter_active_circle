import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

class SignUpWithGoogle extends StatefulWidget {
  final Function(BuildContext, String) onSignInComplete;

  const SignUpWithGoogle({super.key, required this.onSignInComplete});

  @override
  SignUpWithGoogleState createState() => SignUpWithGoogleState();
}

class SignUpWithGoogleState extends State<SignUpWithGoogle> {
  @override
  Widget build(BuildContext context) {
    return SignInButton(
      Buttons.googleDark,
      text: "Googleでアカウント作成",
      onPressed: () async {
        try {
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final AuthCredential credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted && userCredential.user != null) {
              widget.onSignInComplete(context, userCredential.user!.uid);
            }
          }
        } catch (e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Googleアカウントでのサインインに失敗しました。')),
          );
        }
      },
    );
  }
}