import 'package:challo/pages/delete_account.dart';
import 'package:challo/pages/password_change.dart';
import 'package:challo/widgets/text_only_button.dart';
import 'package:flutter/material.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({Key? key}) : super(key: key);

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextOnlyButton(
                    mainText: 'Change Password',
                    onPress: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PasswordChange()));
                    }),
                TextOnlyButton(
                  mainText: 'Delete Account',
                  onPress: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DeleteAccount()));
                  },
                  whetherborderbottom: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
