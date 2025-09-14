/// Test credentials for development auto-login functionality
/// Based on backend integration guide documentation
class TestCredentials {
  static const List<TestAccount> testAccounts = [
    TestAccount(
      email: 'user@pulselink.com',
      password: 'User123!',
      role: 'USER',
      name: 'John User',
      description: 'Regular dating app user',
      avatar: '👤',
    ),
    TestAccount(
      email: 'moderator@pulselink.com',
      password: 'Mod123!',
      role: 'MODERATOR',
      name: 'Jane Moderator',
      description: 'Content moderator with limited admin access',
      avatar: '👮‍♀️',
    ),
    TestAccount(
      email: 'admin@pulselink.com',
      password: 'Admin123!',
      role: 'ADMIN',
      name: 'Mike Administrator',
      description: 'System administrator',
      avatar: '👨‍💼',
    ),
    TestAccount(
      email: 'superadmin@pulselink.com',
      password: 'SuperAdmin123!',
      role: 'SUPER_ADMIN',
      name: 'Sarah SuperAdmin',
      description: 'Super administrator with highest access',
      avatar: '👩‍💻',
    ),
  ];

  /// Get test account by email
  static TestAccount? getByEmail(String email) {
    try {
      return testAccounts.firstWhere((account) => account.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Get test account by role
  static TestAccount? getByRole(String role) {
    try {
      return testAccounts.firstWhere((account) => account.role == role);
    } catch (e) {
      return null;
    }
  }

  /// Check if app is in development mode for auto-login
  static bool get isDevelopmentMode {
    // Only enable auto-login in debug mode
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}

class TestAccount {
  final String email;
  final String password;
  final String role;
  final String name;
  final String description;
  final String avatar;

  const TestAccount({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    required this.description,
    required this.avatar,
  });

  @override
  String toString() => '$name ($role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestAccount && other.email == email;
  }

  @override
  int get hashCode => email.hashCode;
}
