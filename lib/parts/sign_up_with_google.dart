import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../pages/create_nickname.dart';

class SignUpWithGoogle extends StatefulWidget {
  const SignUpWithGoogle({super.key});

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
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const CreateNickname()),
              );
            }
          }
        } catch (e) {
          print(e);
        }
      },
    );
  }
}