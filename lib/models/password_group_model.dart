import 'package:flutter/material.dart';
import 'package:pass_keeper/models/password_model.dart';

class PasswordGroupModel {
  final String name;
  final IconData icon;
  final List<PasswordModel> items;

  const PasswordGroupModel({
    required this.name,
    required this.icon,
    required this.items,
  });
}
