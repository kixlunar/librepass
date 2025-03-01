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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For compute
import 'package:librepass/main.dart';
import 'encryption.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

Future<bool> checkMasterPass(String password) async {
  try {
    String getVaultPath() {
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      return p.join(exeDir, 'vault.json');
    }

    final file = File(getVaultPath());
    final vaultEncryptedContentBad =
        await file.readAsString().timeout(const Duration(milliseconds: 1000));

    final encryptedPrev = jsonDecode(vaultEncryptedContentBad);

    decryptJsonString(
      password,
      encryptedPrev['iv'],
      encryptedPrev['cipher'],
      encryptedPrev['salt'],
    ); // Attempt decryption; if it fails, an exception will be thrown
    return true; // If decryption succeeds, password is valid
  } catch (e) {
    return false; // If anything fails (file read, JSON decode, decryption), password is invalid
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;
  String decryptedJson = '';
  String masterPassword = '';

  void showLoadingPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Verifying..."),
              ],
            ),
          ),
        );
      },
    );
  }

  // Top-level function for compute

  Future<void> setDecryptedJson(String password) async {
    String getVaultPath() {
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      return p.join(exeDir, 'vault.json');
    }

    final file = File(getVaultPath());
    final vaultEncryptedContentBad =
        await file.readAsString().timeout(const Duration(milliseconds: 1000));

    if (kDebugMode) {
      print("vaultEncryptedContentBad: $vaultEncryptedContentBad");
    }

    final encryptedPrev = jsonDecode(vaultEncryptedContentBad);

    var decrypted = decryptJsonString(password, encryptedPrev['iv'],
        encryptedPrev['cipher'], encryptedPrev['salt']);
    decryptedJson = decrypted;
    if (kDebugMode) {
      print("decrypted");
    }
  }

  Future<bool> _checkMasterPass(String password) async {
    if (kDebugMode) {
      print("_checkMasterPass Called");
    }
    try {
      String getVaultPath() {
        final exePath = Platform.resolvedExecutable;
        final exeDir = p.dirname(exePath);
        return p.join(exeDir, 'vault.json');
      }

      final file = File(getVaultPath());
      final vaultEncryptedContentBad =
          await file.readAsString().timeout(const Duration(milliseconds: 1000));

      if (kDebugMode) {
        print("vaultEncryptedContentBad: $vaultEncryptedContentBad");
      }

      final encryptedPrev = jsonDecode(vaultEncryptedContentBad);

      var decrypted = decryptJsonString(password, encryptedPrev['iv'],
          encryptedPrev['cipher'], encryptedPrev['salt']);
      decryptedJson = decrypted;
      if (kDebugMode) {
        print("decrypted");
        print("content decrypted: $decryptedJson");
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkmasterpass: $e');
      }
      return false;
    }
  }

  Future<bool> checkmasterpass(String password) async {
    return await compute(_checkMasterPass, password);
  }

  void proceed() {
    if (mounted) {
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => MyHomePage(
            jsonEntries: decryptedJson,
            masterPassword: masterPassword,
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (kDebugMode) {
      print('Login started');
    }
    setState(() {
      _errorMessage = null;
    });

    String password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    if (kDebugMode) {
      print('Showing loading popup');
    }
    showLoadingPopup(context);

    if (kDebugMode) {
      print('Checking password');
    }
    bool isValid = await compute(checkMasterPass, password);

    if (mounted) {
      if (kDebugMode) {
        print('Closing loading popup');
      }
      Navigator.pop(context); // Close the loading popup
    }

    if (kDebugMode) {
      print('Password check result: $isValid');
    }

    if (isValid) {
      if (kDebugMode) {
        print('Proceeding to home page');
      }
      setDecryptedJson(password);
      masterPassword = password;
      proceed();
    } else {
      setState(() {
        _errorMessage = 'Incorrect master password';
      });
    }
    if (kDebugMode) {
      print('Login completed');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                  suffixIcon: IconButton(
                    style: IconButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
