import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:librepass/encryption.dart';
import 'package:smooth_list_view/smooth_list_view.dart';
import 'dart:convert';
import 'startup.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const StartUpPage(), // Start with the startup page
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key, required this.jsonEntries, required this.masterPassword});
  final String jsonEntries;
  final String masterPassword;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<PassEntry> userdata = [];
  bool smooth = false;
  late ScrollController controller;
  static final TextStyle headerStyle =
      GoogleFonts.atkinsonHyperlegible(fontSize: 20);
  static final TextStyle titleStyle =
      GoogleFonts.atkinsonHyperlegible(fontSize: 50);
  static final ButtonStyle iconButtonStyle = IconButton.styleFrom(
    iconSize: 25,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );

  Map<String, dynamic> toJson(iv, cipherText, salt) => {
        'iv': iv,
        'cipher': cipherText,
        'salt': salt,
      };

  String getVaultPath() {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'vault.json');
  }

  Future<File> saveVault() async {
    var content = encryptJsonString(
      widget.masterPassword,
      jsonEncode(userdata.map((entry) => entry.toJson()).toList()),
    );
    final vaultPath = getVaultPath();
    if (kDebugMode) {
      print("Writing to vault: $vaultPath");
    }
    final file = File(vaultPath);
    return await file.writeAsString(
        jsonEncode(toJson(content[0], content[1], content[2])),
        mode: FileMode.writeOnly);
  }

  Future<void> reWriteToVault() {
    return saveVault();
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    if (widget.jsonEntries.isEmpty) {
      //_addEntry("test", "test", "test");
      return;
    }

    for (var entry in jsonDecode(widget.jsonEntries)) {
      userdata.add(PassEntry(
        title: entry['title'],
        username: entry['username'],
        password: entry['password'],
      ));
    }

    saveVault();
  }

  void _addEntry(String title, String username, String password) {
    userdata.add(PassEntry(
      title: title,
      username: username,
      password: password,
    ));
    saveVault();
  }

  void _deleteEntry(int index) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Delete "${userdata[index].title}"?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                userdata.removeAt(index);
                saveVault();
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Add New Entry',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Password is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final title = titleController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();
                setState(() {
                  _addEntry(title, username, password);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEntryDialog(int index) {
    final PassEntry currentEntry = userdata[index];
    final TextEditingController titleController =
        TextEditingController(text: currentEntry.title);
    final TextEditingController usernameController =
        TextEditingController(text: currentEntry.username);
    final TextEditingController passwordController =
        TextEditingController(text: currentEntry.password);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Entry',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Password is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final title = titleController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();
                setState(() {
                  userdata[index] = PassEntry(
                    title: title,
                    username: username,
                    password: password,
                  );
                });
                saveVault();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double listWidth = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: Text(
                  "Libre Pass",
                  style: titleStyle,
                ),
              ),
              IconButton(
                onPressed: _showAddEntryDialog,
                icon: const Icon(Icons.add_rounded),
                style: iconButtonStyle,
              ),
            ],
          ),
          Container(
            width: listWidth,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: Colors.grey,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(left: 15)),
                SizedBox(
                  width: listWidth / 4,
                  child: Text("Title", style: headerStyle),
                ),
                SizedBox(
                  width: listWidth / 4,
                  child: Text("Username", style: headerStyle),
                ),
                const Padding(padding: EdgeInsets.only(left: 40)),
                Text("Password", style: headerStyle),
                SizedBox(width: listWidth / 4),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              width: listWidth,
              height: MediaQuery.of(context).size.height * 0.8,
              child: userdata.isEmpty
                  ? const Center(child: Text('No entries yet'))
                  : SmoothListView.builder(
                      smoothScroll: smooth,
                      duration: const Duration(milliseconds: 100),
                      controller: controller,
                      itemCount: userdata.length,
                      itemBuilder: (context, index) {
                        return LibrePassRep(
                          indexVal: index,
                          username: userdata[index].username,
                          title: userdata[index].title,
                          onDelete: () => _deleteEntry(index),
                          password: userdata[index].password,
                          onEdit: () => _showEditEntryDialog(index),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class LibrePassRep extends StatefulWidget {
  const LibrePassRep({
    super.key,
    required this.username,
    required this.title,
    required this.password,
    required this.indexVal,
    required this.onDelete,
    required this.onEdit,
  });

  final int indexVal;
  final String username;
  final String title;
  final String password;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  State<LibrePassRep> createState() => _LibrePassRepState();
}

class _LibrePassRepState extends State<LibrePassRep> {
  late Color bgclr;

  static final ButtonStyle iconButtonStyle = IconButton.styleFrom(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );

  void _showCopyDialog(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label copied!'),
        content: CountdownProgress(
          onComplete: () {
            Navigator.pop(context);
            Clipboard.setData(const ClipboardData(text: ''));
          },
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(const ClipboardData(text: ''));
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bgclr = Theme.of(context).colorScheme.surfaceContainer;
  }

  @override
  Widget build(BuildContext context) {
    final defaultBg = Theme.of(context).colorScheme.surfaceContainer;
    final hoverBg = Theme.of(context).colorScheme.surfaceContainerHigh;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: ElevatedButton(
        onHover: (value) => setState(() {
          bgclr = value ? hoverBg : defaultBg;
        }),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgclr,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8 / 4,
              child: Text(widget.title),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _showCopyDialog(widget.username, "username"),
                  icon: const Icon(Icons.copy_rounded),
                  style: iconButtonStyle,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8 / 4,
                  child: Text(widget.username),
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8 / 4,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        _showCopyDialog(widget.password, "password"),
                    icon: const Icon(Icons.copy_rounded),
                    style: iconButtonStyle,
                  ),
                  const Text("********"),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  style: iconButtonStyle,
                ),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: Icon(
                    Icons.edit_rounded,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  style: iconButtonStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PassEntry {
  final String title;
  final String username;
  final String password;

  const PassEntry({
    required this.title,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'username': username,
        'password': password,
      };

  factory PassEntry.fromJson(Map<String, dynamic> json) => PassEntry(
        title: json['title'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
      );
}

String toJsonString(List<PassEntry> passEntries) {
  return jsonEncode(passEntries.map((entry) => entry.toJson()).toList());
}

class CountdownProgress extends StatefulWidget {
  final VoidCallback? onComplete;

  const CountdownProgress({super.key, this.onComplete});

  @override
  State<CountdownProgress> createState() => _CountdownProgressState();
}

class _CountdownProgressState extends State<CountdownProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );

    _controller.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_countdown',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _controller.value,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey[400]!,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
