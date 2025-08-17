class PasswordModel {
  final String name;
  final String login;
  final String password;
  final String? notes;

  PasswordModel({
    required this.name,
    required this.login,
    required this.password,
    this.notes,
  });

  PasswordModel copyWith({
    String? name,
    String? login,
    String? password,
    String? notes = '',
  }) {
    return PasswordModel(
      name: name ?? this.name,
      login: login ?? this.login,
      password: password ?? this.password,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'login': login,
        'password': password,
        if (notes != null) 'notes': notes,
      };

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    return PasswordModel(
      name: (json['name'] ?? '').toString(),
      login: (json['login'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      notes: json['notes']?.toString(),
    );
  }
}
