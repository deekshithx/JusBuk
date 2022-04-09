import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jusbuk/utils/jusbuk_utils.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({required this.user, Key? key}) : super(key: key);
  final User user;
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 5),
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back)),
                const Text(
                  'JusBuk',
                  style: TextStyle(fontSize: 30),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
                'Hello\n${widget.user.displayName ?? widget.user.email ?? 'User'}',
                style: const TextStyle(fontSize: 15)),
            const SizedBox(
              height: 200,
            ),
            ListTile(
              tileColor: Colors.grey[400],
              leading: const Icon(Icons.airline_seat_recline_normal),
              title: const Text('About Developer'),
              onTap: () {
                Utils().launchURL('https://www.linkedin.com/in/deekshithx/');
              },
            ),
            const Divider(),
            ListTile(
              tileColor: Colors.grey[400],
              leading: const Icon(Icons.exit_to_app),
              title: const Text('SignOut'),
              onTap: FirebaseAuth.instance.signOut,
            )
          ],
        ),
      ),
    );
  }
}
