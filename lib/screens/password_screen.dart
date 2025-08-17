import 'package:flutter/material.dart';
import 'package:pass_keeper/components/input.dart';
import 'package:pass_keeper/models/password_model.dart';

class PasswordScreen extends StatefulWidget {
  final String? title;
  final String? buttonText;
  final PasswordModel? passwordItem;
  final List<String>? allGroups;

  const PasswordScreen({
    super.key,
    this.passwordItem,
    this.title,
    this.buttonText,
    this.allGroups,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  String selectedGroup = 'Other';

  List<String> groups = ['Mail', 'Work', 'Other'];
  PasswordModel passwordItem = PasswordModel(
    name: '',
    login: '',
    password: '',
    notes: '',
  );

  final Map<String, Function(String)> inputHandlers = {};
  final TextEditingController _groupController = TextEditingController();

  List<String> _filteredGroups = [];
  bool _showSuggestions = false;
  bool _initialized = false;
  String _title = 'Password';
  String _buttonText = 'Save';
  String? _nameError;
  String? _loginError;
  String? _passwordError;
  String? _groupError;
  bool _isEditing = false;
  late PasswordModel _originalItem;
  late String _originalGroupName;

  void _clearForm() {
    setState(() {
      passwordItem = passwordItem.copyWith(
        name: '',
        login: '',
        password: '',
        notes: '',
      );
      _nameError = null;
      _loginError = null;
      _passwordError = null;
      _groupError = null;

      selectedGroup = 'Other';
      _groupController.text = 'Other';
      _showSuggestions = false;
      _filteredGroups.clear();
    });
  }

  void handlePasswordSave() {
    final groupText = _groupController.text.trim();
    if (groupText.isEmpty) {
      setState(() => _groupError = 'Group is required');
    }

    final ok = _validate();
    if (!ok) {
      final missing = [
        if (_nameError != null) 'Name',
        if (_loginError != null) 'Login',
        if (_passwordError != null) 'Password',
        if (_groupError != null) 'Group',
      ].join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill required fields: $missing'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    selectedGroup = groupText;
    Navigator.pop(context, {
      'passwordItem': passwordItem,
      'groupName':
          selectedGroup.substring(0, 1).toUpperCase() +
          selectedGroup.substring(1),
    });
  }

  void handleInputChange(String field, String data) {
    if (inputHandlers.containsKey(field)) {
      setState(() => inputHandlers[field]!(data));
    }
  }

  Widget buildInputFields() => Column(
    children: [
      Input(
        placeholder: 'Name',
        initialValue: passwordItem.name,
        errorText: _nameError,
        onChanged: (value) => handleInputChange('name', value),
      ),
      SizedBox(height: 16),
      Input(
        placeholder: 'Login',
        initialValue: passwordItem.login,
        errorText: _loginError,
        onChanged: (value) => handleInputChange('login', value),
      ),
      SizedBox(height: 16),
      Input(
        placeholder: 'Password',
        showGenerateButton: true,
        initialValue: passwordItem.password,
        errorText: _passwordError,
        onChanged: (value) => handleInputChange('password', value),
      ),
      SizedBox(height: 16),
      Input(
        placeholder: 'Notes',
        isTextArea: true,
        initialValue: passwordItem.notes,
        onChanged: (value) => handleInputChange('notes', value),
      ),
    ],
  );

  Widget buildGroupDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _groupController,
        decoration: InputDecoration(
          hintText: 'Group (type to search or create new)',
          hintStyle: const TextStyle(color: Colors.grey),
          border: const UnderlineInputBorder(),
          errorText: _groupError,
          suffixIcon: _showSuggestions
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _groupController.clear();
                      _showSuggestions = false;
                      _filteredGroups.clear();
                    });
                  },
                )
              : const Icon(Icons.search),
        ),
        onChanged: _onGroupSearchChanged,
        onTap: () {
          if (!_showSuggestions) {
            _onGroupSearchChanged(_groupController.text);
          }
        },
      ),
      if (_showSuggestions && _filteredGroups.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Column(
            children: _filteredGroups.map((group) {
              return ListTile(
                dense: true,
                title: Text(group, style: const TextStyle(color: Colors.white)),
                onTap: () => _selectGroup(group),
              );
            }).toList(),
          ),
        ),
    ],
  );

  void _onGroupSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _showSuggestions = false;
        _filteredGroups.clear();
      } else {
        _showSuggestions = true;
        _filteredGroups = groups
            .where((group) => group.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _groupError = null;
      }
    });
  }

  void _selectGroup(String group) {
    setState(() {
      selectedGroup = group;
      _groupController.text = group;
      _showSuggestions = false;
      _filteredGroups.clear();
      _groupError = null;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _groupController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    groups = (args != null && args['allGroups'] is List<String>)
        ? List<String>.from(args['allGroups'] as List)
        : (widget.allGroups ?? ['Mail', 'Work', 'Other']);
    passwordItem = (args != null && args['passwordItem'] is PasswordModel)
        ? args['passwordItem'] as PasswordModel
        : (widget.passwordItem ??
              PasswordModel(name: '', login: '', password: '', notes: ''));

    selectedGroup = (args != null && args['groupName'] is String)
        ? args['groupName'] as String
        : 'Other';
    _groupController.text = selectedGroup;

    _isEditing = args != null && args['passwordItem'] is PasswordModel;
    _originalItem = passwordItem;
    _originalGroupName = selectedGroup;

    _title = (args != null && args['title'] is String)
        ? args['title'] as String
        : (widget.title ?? 'Password');
    _buttonText = (args != null && args['buttonText'] is String)
        ? args['buttonText'] as String
        : (widget.buttonText ?? 'Save');

    inputHandlers.addAll({
      'name': (val) {
        passwordItem = passwordItem.copyWith(name: val);
        _nameError = val.trim().isEmpty ? 'Name is required' : null;
      },
      'login': (val) {
        passwordItem = passwordItem.copyWith(login: val);
        _loginError = val.trim().isEmpty ? 'Login is required' : null;
      },
      'password': (val) {
        passwordItem = passwordItem.copyWith(password: val);
        _passwordError = val.trim().isEmpty ? 'Password is required' : null;
      },
      'notes': (val) => passwordItem = passwordItem.copyWith(notes: val),
    });

    _initialized = true;
  }

  bool _validate() {
    final name = passwordItem.name.trim();
    final login = passwordItem.login.trim();
    final pwd = passwordItem.password.trim();
    final group = _groupController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _loginError = login.isEmpty ? 'Login is required' : null;
      _passwordError = pwd.isEmpty ? 'Password is required' : null;
      _groupError = group.isEmpty ? 'Group is required' : null;
    });

    return _nameError == null &&
        _loginError == null &&
        _passwordError == null &&
        _groupError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            _title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      backgroundColor: const Color.fromARGB(255, 40, 40, 40),
                      title: const Text(
                        'Delete pass',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this item? This action cannot be undone.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true) {
                  Navigator.pop(context, {
                    'delete': true,
                    'passwordItem': _originalItem,
                    'groupName': _originalGroupName,
                  });
                }
              },
            ),
          if (!_isEditing)
            IconButton(
              tooltip: 'Clear form',
              icon: const Icon(Icons.cleaning_services),
              onPressed: _clearForm,
            ),
        ],
        backgroundColor: Color.fromARGB(255, 31, 31, 31),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        height: double.infinity,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildInputFields(),
                    SizedBox(height: 16),
                    buildGroupDropdown(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handlePasswordSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 57, 44, 114),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _buttonText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
