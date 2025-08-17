import 'package:flutter/material.dart';
import 'dart:math';

class Input extends StatefulWidget {
  final String placeholder;
  final bool isTextArea;
  final bool showGenerateButton;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const Input({
    super.key,
    required this.placeholder,
    this.isTextArea = false,
    this.showGenerateButton = false,
    this.initialValue,
    this.onChanged,
    this.errorText,
  });

  @override
  State<StatefulWidget> createState() {
    return _InputState();
  }
}

class _InputState extends State<Input> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<String> _charSets = [
    'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    '0123456789',
    '!@#\$%^&*()_+-=[]{}|;:,.<>?',
  ];
  static const String _allChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';

  void generateRandomPassword() {
    final Random random = Random.secure();
    const int passwordLength = 16;
    final List<int> password = List.filled(passwordLength, 0);

    for (int i = 0; i < _charSets.length; i++) {
      final charSet = _charSets[i];
      password[i] = charSet.codeUnitAt(random.nextInt(charSet.length));
    }

    for (int i = _charSets.length; i < passwordLength; i++) {
      password[i] = _allChars.codeUnitAt(random.nextInt(_allChars.length));
    }

    for (int i = passwordLength - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final int temp = password[i];
      password[i] = password[j];
      password[j] = temp;
    }

    _controller.text = String.fromCharCodes(password);
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            maxLines: widget.isTextArea ? 4 : 1,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              hintText: widget.placeholder,
              hintStyle: const TextStyle(color: Colors.grey),
              errorText: widget.errorText,
            ),
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
            controller: _controller,
          ),
        ),
        if (widget.showGenerateButton)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 57, 44, 114),
            ),
            icon: const Icon(Icons.refresh),
            onPressed: generateRandomPassword,
          ),
      ],
    );
  }
}
