class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;
  final List<String> roles;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle id as either int or String
    int userId;
    if (json['id'] is int) {
      userId = json['id'];
    } else if (json['id'] is String) {
      userId = int.tryParse(json['id']) ?? 0;
    } else {
      userId = 0;
    }

    // Handle roles as list of strings
    List<String> rolesList = [];
    if (json['roles'] is List) {
      rolesList = (json['roles'] as List).map((role) {
        if (role is String) {
          return role;
        } else if (role is Map && role['name'] != null) {
          return role['name'].toString();
        } else {
          return role.toString();
        }
      }).toList();
    }

    return User(
      id: userId,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      roles: rolesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'roles': roles,
    };
  }

  bool get isAdmin {
    // Check if roles list contains 'ADMIN' string
    return roles.any((role) => role.toUpperCase().contains('ADMIN'));
  }
}
