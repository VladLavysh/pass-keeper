import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_keeper/models/password_model.dart';

enum _PasswordItemAction { copyLogin, copyPassword }

class PasswordItem extends StatelessWidget {
  final PasswordModel passwordItem;
  final VoidCallback? onTap;

  const PasswordItem({super.key, required this.passwordItem, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        margin: EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color.fromARGB(255, 65, 65, 65),
            width: 0.5,
          ),
          color: Color.fromARGB(255, 20, 20, 20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_2, size: 18, color: Colors.grey[400]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          passwordItem.name,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<_PasswordItemAction>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color.fromARGB(255, 31, 31, 31),
              onSelected: (action) async {
                switch (action) {
                  case _PasswordItemAction.copyLogin:
                    await Clipboard.setData(
                      ClipboardData(text: passwordItem.login),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login copied to clipboard'),
                      ),
                    );
                    break;
                  case _PasswordItemAction.copyPassword:
                    await Clipboard.setData(
                      ClipboardData(text: passwordItem.password),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password copied to clipboard'),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _PasswordItemAction.copyLogin,
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.white),
                    title: Text(
                      'Copy login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: _PasswordItemAction.copyPassword,
                  child: ListTile(
                    leading: Icon(Icons.lock, color: Colors.white),
                    title: Text(
                      'Copy password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
