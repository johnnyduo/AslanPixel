/// Profile privacy mode — controls visibility of room, stats, and portfolio
enum PrivacyMode { public, friendsOnly, private }

extension PrivacyModeValue on PrivacyMode {
  String get value {
    switch (this) {
      case PrivacyMode.public:
        return 'public';
      case PrivacyMode.friendsOnly:
        return 'friends_only';
      case PrivacyMode.private:
        return 'private';
    }
  }

  static PrivacyMode fromString(String? value) {
    switch (value) {
      case 'friends_only':
        return PrivacyMode.friendsOnly;
      case 'private':
        return PrivacyMode.private;
      default:
        return PrivacyMode.public;
    }
  }
}
