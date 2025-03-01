/*    
    Copyright (C) 2025  kixlunar

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:librepass/login.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'encryption.dart';

class StartUpPage extends StatefulWidget {
  const StartUpPage({super.key});

  @override
  State<StartUpPage> createState() => _StartUpPageState();
}

class _StartUpPageState extends State<StartUpPage> {
  // Get the path to vault.json in the same directory as the executable
  String getVaultPath() {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'vault.json');
  }

  // Check if vault.json exists and is not empty
  bool isVaultSetUp() {
    final vaultPath = getVaultPath();
    final file = File(vaultPath);
    return file.existsSync() && file.lengthSync() > 0;
  }

  Map<String, dynamic> toJson(iv, cipherText, salt) => {
        'iv': iv,
        'cipher': cipherText,
        'salt': salt,
      };

  // Save content to vault.json (use only when no vault exists)
  // WILL OVERWRITE ALL VAULT CONTENT
  Future<File> saveVault(String masterKey) async {
    var content = encryptJsonString(masterKey, "");
    final vaultPath = getVaultPath();
    if (kDebugMode) {
      print("Writing to vault: $vaultPath");
    }
    final file = File(vaultPath);
    return await file.writeAsString(
        jsonEncode(toJson(content[0], content[1], content[2])),
        mode: FileMode.writeOnly);
  }

  // Perform initial setup with the master key
  Future<void> initialSetup(String masterKey) async {
    if (kDebugMode) {
      print("Running initial setup");
    }
    await saveVault(masterKey);
  }

  Future<void> _showOnboardingProcess() async {
    // Step 1: Welcome the user
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Libre Pass!'),
          content: const Text(
              'We’re excited to have you on board. Let’s get you set up.'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    // Step 2: Master key prompt
    final TextEditingController masterKeyController = TextEditingController();
    String? masterKey;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Your Master Key'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please create a strong master key to secure your vault.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: masterKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Master Key',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (masterKeyController.text.trim().isNotEmpty) {
                  masterKey = masterKeyController.text.trim();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Master key cannot be empty')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    // Step 3: Run initial setup and navigate to home screen
    if (masterKey != null && mounted) {
      await initialSetup(masterKey!);
      if (kDebugMode) {
        print("Onboarding complete, navigating to home screen");
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Login(),
        ),
      );
    }
  }

  Future<void> _checkVaultAndNavigate() async {
    if (isVaultSetUp()) {
      if (kDebugMode) {
        print("Vault is set up, navigating to login screen");
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const Login(),
          ),
        );
      }
    } else {
      if (kDebugMode) {
        print("Vault is not set up, starting onboarding process");
      }
      await _showOnboardingProcess();
    }
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("Startup init state called");
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVaultAndNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading..."),
          ],
        ),
      ),
    );
  }
}
