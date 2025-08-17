import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:pass_keeper/components/password_list.dart';
import 'package:pass_keeper/helpers/constants.dart';
import 'package:pass_keeper/models/password_model.dart';
import 'package:pass_keeper/models/password_group_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pass_keeper/helpers/crypto_helper.dart';
import 'package:pass_keeper/services/auth_service.dart';

enum _ImportExportAction { importJson, exportJson }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // If app isn't unlocked, redirect to lock screen
    if (!AuthService.instance.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/lock');
      });
    }
  }

  final List<PasswordGroupModel> passwordGroups = [
    PasswordGroupModel(
      name: 'Mail',
      icon: Icons.mail,
      items: [
        PasswordModel(
          name: "vlad1",
          login: "lavyshvlad1@gmail.com",
          password: "somePassword123",
        ),
      ],
    ),
    PasswordGroupModel(
      name: 'Work',
      icon: Icons.work,
      items: [
        PasswordModel(
          name: "vlad1",
          login: "lavyshvlad1@gmail.com",
          password: "somePassword123",
        ),
      ],
    ),
    PasswordGroupModel(
      name: 'Other',
      icon: Icons.folder,
      items: [
        PasswordModel(
          name: "cloud",
          login: "someTesh@gmail.com",
          password: "fff123somePasswor",
        ),
      ],
    ),
  ];
  List<String> get groups => passwordGroups.map((g) => g.name).toList();

  String searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  Future<String?> _askPassphrase({required String title}) async {
    final controller = TextEditingController();
    String? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 31, 31, 31),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter passphrase'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                result = controller.text.trim();
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result == null || result!.isEmpty) return null;
    return result;
  }

  IconData _getIconByName(String iconName) {
    final name = iconName.trim().toLowerCase();
    return iconMap[name] ?? Icons.folder;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = value.trim();
      });
    });
  }

  void handleAddPasswordItem() async {
    final result = await Navigator.pushNamed(
      context,
      '/add',
      arguments: {
        'title': 'New Pass',
        'buttonText': 'Save',
        'allGroups': groups,
      },
    );

    if (result != null) {
      final data = result as Map;
      final newPasswordItem = data['passwordItem'] as PasswordModel;
      final groupName = data['groupName'] as String;

      _addPasswordToGroup(newPasswordItem, groupName);
    }
  }

  void handleEditPasswordItem(
    PasswordModel passwordItem,
    String currentGroupName,
  ) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit',
      arguments: {
        'title': 'Edit Pass',
        'buttonText': 'Update',
        'passwordItem': passwordItem,
        'groupName': currentGroupName,
        'allGroups': groups,
      },
    );

    if (result != null) {
      final data = result as Map;
      if (data['delete'] == true) {
        final toDelete = data['passwordItem'] as PasswordModel;
        final groupName = data['groupName'] as String;
        _deletePasswordItem(toDelete, groupName);
        return;
      }

      final updatedPasswordItem = data['passwordItem'] as PasswordModel;
      final newGroupName = data['groupName'] as String;

      _updatePasswordItem(
        passwordItem,
        updatedPasswordItem,
        currentGroupName,
        newGroupName,
      );
    }
  }

  void _addPasswordToGroup(PasswordModel passwordItem, String groupName) {
    setState(() {
      final groupIndex = passwordGroups.indexWhere((g) => g.name == groupName);
      if (groupIndex != -1) {
        passwordGroups[groupIndex].items.add(passwordItem);
      } else {
        final newGroup = PasswordGroupModel(
          name: groupName,
          icon: _getIconByName(groupName),
          items: [passwordItem],
        );
        passwordGroups.add(newGroup);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pass has been created successfully!'),
        backgroundColor: Colors.lightGreenAccent,
      ),
    );
  }

  void _updatePasswordItem(
    PasswordModel oldItem,
    PasswordModel newItem,
    String oldGroupName,
    String newGroupName,
  ) {
    setState(() {
      int oldGroupIndex = passwordGroups.indexWhere(
        (g) => g.name == oldGroupName,
      );
      int newGroupIndex = passwordGroups.indexWhere(
        (g) => g.name == newGroupName,
      );

      int _findItemIndex(List<PasswordModel> list, PasswordModel target) {
        final byIdentity = list.indexWhere((it) => identical(it, target));
        if (byIdentity != -1) return byIdentity;
        return list.indexWhere(
          (it) =>
              it.name == target.name &&
              it.login == target.login &&
              it.password == target.password,
        );
      }

      if (oldGroupName == newGroupName && oldGroupIndex != -1) {
        final items = passwordGroups[oldGroupIndex].items;
        final idx = _findItemIndex(items, oldItem);
        if (idx != -1) {
          items[idx] = newItem;
        } else {
          items.add(newItem);
        }
        return;
      }

      if (oldGroupIndex != -1) {
        final items = passwordGroups[oldGroupIndex].items;
        final idx = _findItemIndex(items, oldItem);
        if (idx != -1) {
          items.removeAt(idx);
        } else {
          items.removeWhere(
            (it) =>
                it.name == oldItem.name &&
                it.login == oldItem.login &&
                it.password == oldItem.password,
          );
        }

        if (items.isEmpty) {
          passwordGroups.removeAt(oldGroupIndex);
          newGroupIndex = passwordGroups.indexWhere(
            (g) => g.name == newGroupName,
          );
          oldGroupIndex = -1;
        }
      }

      if (newGroupIndex != -1) {
        passwordGroups[newGroupIndex].items.add(newItem);
      } else {
        final newGroup = PasswordGroupModel(
          name: newGroupName,
          icon: _getIconByName(newGroupName),
          items: [newItem],
        );
        passwordGroups.add(newGroup);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pass has been updated successfully!'),
        backgroundColor: Colors.lightGreenAccent,
      ),
    );
  }

  void _deletePasswordItem(PasswordModel item, String groupName) {
    setState(() {
      final groupIndex = passwordGroups.indexWhere((g) => g.name == groupName);
      if (groupIndex == -1) return;

      int _findItemIndex(List<PasswordModel> list, PasswordModel target) {
        final byIdentity = list.indexWhere((it) => identical(it, target));
        if (byIdentity != -1) return byIdentity;
        return list.indexWhere(
          (it) =>
              it.name == target.name &&
              it.login == target.login &&
              it.password == target.password,
        );
      }

      final items = passwordGroups[groupIndex].items;
      final idx = _findItemIndex(items, item);
      if (idx != -1) {
        items.removeAt(idx);
      } else {
        items.removeWhere(
          (it) =>
              it.name == item.name &&
              it.login == item.login &&
              it.password == item.password,
        );
      }

      if (items.isEmpty) {
        passwordGroups.removeAt(groupIndex);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pass has been deleted successfully!'),
        backgroundColor: Colors.lightGreenAccent,
      ),
    );
  }

  void _onImportExportSelected(_ImportExportAction action) {
    switch (action) {
      case _ImportExportAction.importJson:
        _importJson();
        break;
      case _ImportExportAction.exportJson:
        _exportJson();
        break;
    }
  }

  Future<void> _exportJson() async {
    try {
      final data = {
        'groups': passwordGroups
            .map(
              (g) => {
                'name': g.name,
                'items': g.items.map((it) => it.toJson()).toList(),
              },
            )
            .toList(),
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final passphrase = await _askPassphrase(title: 'Set export passphrase');
      if (passphrase == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export canceled.')));
        return;
      }

      final encryptedEnvelope = await CryptoHelper.encryptString(
        plaintext: jsonStr,
        passphrase: passphrase,
      );

      String? savedPath;

      if (Platform.isAndroid || Platform.isIOS) {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save passwords JSON',
          fileName: 'passwords.enc.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(encryptedEnvelope),
        );
      } else {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save passwords JSON',
          fileName: 'passwords.enc.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (savedPath != null) {
          final file = File(savedPath);
          await file.writeAsString(
            encryptedEnvelope,
            mode: FileMode.write,
            flush: true,
          );
        }
      }

      if (!mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export canceled.')));
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to: $savedPath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Import canceled.')));
        return;
      }

      final picked = result.files.single;
      String content;
      if (picked.path != null) {
        content = await File(picked.path!).readAsString();
      } else if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!);
      } else {
        throw 'Unable to read selected file';
      }

      Map<String, dynamic> map = json.decode(content) as Map<String, dynamic>;
      final isEncrypted =
          map.containsKey('cipher') && map.containsKey('ciphertext');

      if (isEncrypted) {
        final passphrase = await _askPassphrase(
          title: 'Enter passphrase to decrypt',
        );
        if (passphrase == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import canceled (no passphrase).')),
          );
          return;
        }
        try {
          final decryptedJson = await CryptoHelper.decryptString(
            encryptedEnvelopeJson: content,
            passphrase: passphrase,
          );
          map = json.decode(decryptedJson) as Map<String, dynamic>;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Decryption failed. Check passphrase.'),
            ),
          );
          return;
        }
      }
      final List<dynamic> groupsJson = map['groups'] ?? [];

      final List<PasswordGroupModel> imported = groupsJson.map((g) {
        final name = (g['name'] ?? 'Other').toString();
        final itemsJson = (g['items'] as List<dynamic>?) ?? [];
        final items = itemsJson
            .map((it) => PasswordModel.fromJson(it as Map<String, dynamic>))
            .toList();
        return PasswordGroupModel(
          name: name,
          icon: _getIconByName(name),
          items: items,
        );
      }).toList();

      setState(() {
        passwordGroups
          ..clear()
          ..addAll(imported);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imported from JSON successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String q = searchQuery.trim().toLowerCase();
    final List<PasswordGroupModel> displayedGroups = q.isEmpty
        ? passwordGroups
        : passwordGroups
              .map((g) {
                final filtered = g.items
                    .where((it) => it.login.toLowerCase().contains(q))
                    .toList();
                if (filtered.isEmpty) return null;
                return PasswordGroupModel(
                  name: g.name,
                  icon: g.icon,
                  items: filtered,
                );
              })
              .whereType<PasswordGroupModel>()
              .toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Lock',
          icon: const Icon(Icons.lock_outline),
          onPressed: () async {
            await AuthService.instance.lock();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/lock');
          },
        ),
        actions: [
          PopupMenuButton<_ImportExportAction>(
            icon: const Icon(Icons.import_export),
            color: const Color.fromARGB(255, 31, 31, 31),
            onSelected: _onImportExportSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ImportExportAction.importJson,
                child: ListTile(
                  leading: Icon(Icons.file_upload, color: Colors.white),
                  title: Text(
                    'Import JSON',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              PopupMenuItem(
                value: _ImportExportAction.exportJson,
                child: ListTile(
                  leading: Icon(Icons.file_download, color: Colors.white),
                  title: Text(
                    'Export JSON',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
        title: Center(
          child: Text(
            'Passes List',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 31, 31, 31),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 31, 31, 31),
              Color.fromARGB(255, 19, 19, 19),
            ],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration:
                  const InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'Search by Login...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ).copyWith(
                    suffixIcon: (_searchController.text.isEmpty)
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _onSearchChanged('');
                            },
                          ),
                  ),
              onChanged: (v) {
                // Rebuild to toggle suffixIcon visibility
                setState(() {});
                _onSearchChanged(v);
              },
            ),
            Expanded(
              child: PasswordList(
                items: displayedGroups,
                onPasswordTap: handleEditPasswordItem,
                expandAll: q.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: handleAddPasswordItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
