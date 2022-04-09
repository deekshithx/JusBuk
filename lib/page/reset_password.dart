import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jusbuk/main.dart';
import 'package:jusbuk/utils/jusbuk_utils.dart';
import 'package:jusbuk/utils/widgets/custom_text_field.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Reset Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Colors.white),
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const Text(
                    ' Enter Email to receive reset password instructions',
                    style: TextStyle(fontSize: 15)),
                const SizedBox(
                  height: 20,
                ),
                CustomTextField(
                  controller: emailController,
                  hintText: "Enter Email",
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  label: Text(
                    isLoading ? 'Please wait!..' : "Proceed",
                    style: const TextStyle(fontSize: 24),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                                    email: emailController.text)
                                .then((value) {
                              Utils().showSnackBar(context,
                                  'reset password instructions has been sent to your email address');
                            });
                          } on FirebaseAuthException catch (e) {
                            Utils().showSnackBar(context, e.message ?? '');
                          }
                          setState(() {
                            isLoading = false;
                          });
                        },
                  icon: const Icon(Icons.lock_reset_outlined),
                )
              ],
            ),
          ))),
    );
  }
}
