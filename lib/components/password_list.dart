import 'package:flutter/material.dart';
import 'package:pass_keeper/models/password_group_model.dart';
import 'package:pass_keeper/models/password_model.dart';
import 'package:pass_keeper/components/password_item.dart';

class PasswordList extends StatefulWidget {
  final List<PasswordGroupModel> items;
  final Function(PasswordModel, String) onPasswordTap;
  final bool expandAll;

  const PasswordList({
    super.key,
    required this.items,
    required this.onPasswordTap,
    required this.expandAll,
  });

  @override
  State<PasswordList> createState() => _PasswordListState();
}

class _PasswordListState extends State<PasswordList> {
  late List<PasswordGroupModel> _items;

  List<Widget> _buildPasswordList() {
    return _items.map((group) {
      final passwordWidgets = group.items.map((item) {
        return PasswordItem(
          passwordItem: item,
          onTap: () => widget.onPasswordTap(item, group.name),
        );
      }).toList();

      return ExpansionTile(
        key: ValueKey('group-${group.name}-${widget.expandAll}'),
        collapsedBackgroundColor: const Color.fromARGB(255, 31, 31, 31),
        backgroundColor: const Color.fromARGB(255, 22, 22, 22),
        leading: Icon(group.icon, color: Colors.grey[300], size: 28),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        childrenPadding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        initiallyExpanded: widget.expandAll,
        title: Text(
          group.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
          size: 28,
        ),
        children: passwordWidgets,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _items.sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void didUpdateWidget(covariant PasswordList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      setState(() {
        _items = widget.items;
        _items.sort((a, b) => a.name.compareTo(b.name));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16.0),
      children: _buildPasswordList(),
    );
  }
}
