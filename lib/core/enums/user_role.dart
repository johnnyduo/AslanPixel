/// User role stored in Firestore users/{uid}.role
enum UserRoleType { none, admin, user, block, guest }

extension UserRoleTypeValue on UserRoleType {
  String get value {
    switch (this) {
      case UserRoleType.none:
        return 'none';
      case UserRoleType.admin:
        return 'ADMIN';
      case UserRoleType.user:
        return 'USER';
      case UserRoleType.block:
        return 'BLOCK';
      case UserRoleType.guest:
        return 'GUEST';
    }
  }

  static UserRoleType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ADMIN':
        return UserRoleType.admin;
      case 'USER':
        return UserRoleType.user;
      case 'BLOCK':
        return UserRoleType.block;
      case 'GUEST':
        return UserRoleType.guest;
      default:
        return UserRoleType.none;
    }
  }
}
