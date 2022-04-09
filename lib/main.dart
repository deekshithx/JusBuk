import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:jusbuk/api/firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:jusbuk/page/home_page.dart';
import 'package:jusbuk/page/reset_password.dart';
import 'package:jusbuk/utils/jusbuk_utils.dart';
import 'package:jusbuk/utils/widgets/custom_text_field.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JusBuk',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LandingPage(),
      );
}

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return HomePage(user: snapshot.data!);
            } else {
              return const LoginPage();
            }
          }),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailTextController = TextEditingController(),
      passwordController = TextEditingController(),
      nameController = TextEditingController();
  bool isLoading = false, isSignUp = false;

  @override
  void dispose() {
    emailTextController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '\n\n\nWelcome to JusBuk\n\n\n',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              'Enter your ${isSignUp ? 'details' : 'email and password'} to ${isSignUp ? 'Sign Up' : 'Sign In'}\n\n',
              style: const TextStyle(fontSize: 15),
            ),
            if (isSignUp)
              CustomTextField(
                hintText: 'Name',
                controller: nameController,
                keyboardType: TextInputType.name,
              ),
            CustomTextField(
              hintText: 'Email',
              controller: emailTextController,
              keyboardType: TextInputType.emailAddress,
            ),
            CustomTextField(
              hintText: 'Password',
              controller: passwordController,
            ),
            if (!isSignUp) forgetPassword(context),
            const SizedBox(
              height: 25,
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              label: Text(
                isLoading
                    ? 'Please wait!...'
                    : isSignUp
                        ? 'SignUp'
                        : 'Sign In',
                style: const TextStyle(fontSize: 24),
              ),
              onPressed: isLoading
                  ? null
                  : isSignUp
                      ? signUp
                      : signIn,
              icon: const Icon(Icons.lock_open),
            ),
            const SizedBox(
              height: 15,
            ),
            signUpOption()
          ],
        ),
      ),
    ));
  }

  Future signUp() async {
    if (nameController.text.isEmpty ||
        emailTextController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Utils().showSnackBar(context, 'please fill all fields');
    } else {
      setState(() {
        isLoading = true;
      });
      try {
        FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailTextController.text.trim(),
                password: passwordController.text.trim())
            .then((value) {
          Utils().showSnackBar(context, 'Created Account');

          FirebaseFirestore.instance.collection("Users").add({
            "userId": value.user!.uid,
            "name": nameController.text,
            "email": emailTextController.text,
            "password": passwordController.text,
          }).then((_) async {
            try {
              final File file = await Utils.getImageFileFromAssets('hello.png');
              final fileName = p.basename(file.path);
              final destination = 'files/${value.user!.uid}/$fileName';
              var task = FirebaseApi.uploadFile(destination, file);

              if (task == null) return;

              await task.whenComplete(() {
                Phoenix.rebirth(context);
              });
            } on FirebaseException catch (e) {
              Utils().showSnackBar(context, e.message ?? 'something wrong');
            }
          }).catchError((_) {
            print("an error occured");
          });
        }).onError((error, stackTrace) {
          Utils().showSnackBar(context, error.toString());
        });
      } on FirebaseAuthException catch (e) {
        Utils().showSnackBar(context, e.message ?? '');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailTextController.text.trim(),
          password: passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      Utils().showSnackBar(context, e.message ?? '');
    }
    setState(() {
      isLoading = false;
    });
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isSignUp ? "Already have an account?" : "Don't have account?",
            style: const TextStyle(color: Colors.blue)),
        GestureDetector(
          onTap: () {
            setState(() {
              isSignUp = !isSignUp;
            });
          },
          child: Text(
            isSignUp ? "Sign In" : " Sign Up",
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Colors.blue),
          textAlign: TextAlign.right,
        ),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ResetPassword())),
      ),
    );
  }
}
