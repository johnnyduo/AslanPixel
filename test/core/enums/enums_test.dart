import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/core/enums/auth_status.dart';
import 'package:aslan_pixel/core/enums/privacy_mode.dart';
import 'package:aslan_pixel/core/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── AgentType ─────────────────────────────────────────────────────────────
  group('AgentType', () {
    test('has exactly 4 values', () {
      expect(AgentType.values.length, 4);
    });

    test('contains analyst, scout, risk, social', () {
      expect(
        AgentType.values,
        containsAll([
          AgentType.analyst,
          AgentType.scout,
          AgentType.risk,
          AgentType.social,
        ]),
      );
    });

    group('value extension', () {
      test('analyst.value returns "analyst"', () {
        expect(AgentType.analyst.value, 'analyst');
      });

      test('scout.value returns "scout"', () {
        expect(AgentType.scout.value, 'scout');
      });

      test('risk.value returns "risk"', () {
        expect(AgentType.risk.value, 'risk');
      });

      test('social.value returns "social"', () {
        expect(AgentType.social.value, 'social');
      });
    });

    group('displayName extension', () {
      test('analyst.displayName returns "Analyst"', () {
        expect(AgentType.analyst.displayName, 'Analyst');
      });

      test('scout.displayName returns "Scout"', () {
        expect(AgentType.scout.displayName, 'Scout');
      });

      test('risk.displayName returns "Risk"', () {
        expect(AgentType.risk.displayName, 'Risk');
      });

      test('social.displayName returns "Social"', () {
        expect(AgentType.social.displayName, 'Social');
      });
    });

    group('fromString', () {
      test('parses "analyst" (default fallback)', () {
        expect(AgentTypeValue.fromString('analyst'), AgentType.analyst);
      });

      test('parses "scout"', () {
        expect(AgentTypeValue.fromString('scout'), AgentType.scout);
      });

      test('parses "risk"', () {
        expect(AgentTypeValue.fromString('risk'), AgentType.risk);
      });

      test('parses "social"', () {
        expect(AgentTypeValue.fromString('social'), AgentType.social);
      });

      test('returns analyst for null', () {
        expect(AgentTypeValue.fromString(null), AgentType.analyst);
      });

      test('returns analyst for unknown string', () {
        expect(AgentTypeValue.fromString('unknown'), AgentType.analyst);
      });
    });
  });

  // ── AuthStatus ────────────────────────────────────────────────────────────
  group('AuthStatus', () {
    test('has exactly 4 values', () {
      expect(AuthStatus.values.length, 4);
    });

    test('contains notdetermined, notloggedin, loggedin, firstapp', () {
      expect(
        AuthStatus.values,
        containsAll([
          AuthStatus.notdetermined,
          AuthStatus.notloggedin,
          AuthStatus.loggedin,
          AuthStatus.firstapp,
        ]),
      );
    });

    test('enum index ordering is stable', () {
      expect(AuthStatus.notdetermined.index, 0);
      expect(AuthStatus.notloggedin.index, 1);
      expect(AuthStatus.loggedin.index, 2);
      expect(AuthStatus.firstapp.index, 3);
    });
  });

  // ── PrivacyMode ───────────────────────────────────────────────────────────
  group('PrivacyMode', () {
    test('has exactly 3 values', () {
      expect(PrivacyMode.values.length, 3);
    });

    test('contains public, friendsOnly, private', () {
      expect(
        PrivacyMode.values,
        containsAll([
          PrivacyMode.public,
          PrivacyMode.friendsOnly,
          PrivacyMode.private,
        ]),
      );
    });

    group('value extension', () {
      test('public.value returns "public"', () {
        expect(PrivacyMode.public.value, 'public');
      });

      test('friendsOnly.value returns "friends_only"', () {
        expect(PrivacyMode.friendsOnly.value, 'friends_only');
      });

      test('private.value returns "private"', () {
        expect(PrivacyMode.private.value, 'private');
      });
    });

    group('fromString', () {
      test('parses "friends_only"', () {
        expect(PrivacyModeValue.fromString('friends_only'),
            PrivacyMode.friendsOnly);
      });

      test('parses "private"', () {
        expect(
            PrivacyModeValue.fromString('private'), PrivacyMode.private);
      });

      test('returns public for "public"', () {
        expect(
            PrivacyModeValue.fromString('public'), PrivacyMode.public);
      });

      test('returns public for null', () {
        expect(PrivacyModeValue.fromString(null), PrivacyMode.public);
      });

      test('returns public for unknown string', () {
        expect(
            PrivacyModeValue.fromString('whatever'), PrivacyMode.public);
      });
    });
  });

  // ── UserRoleType ──────────────────────────────────────────────────────────
  group('UserRoleType', () {
    test('has exactly 5 values', () {
      expect(UserRoleType.values.length, 5);
    });

    test('contains none, admin, user, block, guest', () {
      expect(
        UserRoleType.values,
        containsAll([
          UserRoleType.none,
          UserRoleType.admin,
          UserRoleType.user,
          UserRoleType.block,
          UserRoleType.guest,
        ]),
      );
    });

    group('value extension', () {
      test('none.value returns "none"', () {
        expect(UserRoleType.none.value, 'none');
      });

      test('admin.value returns "ADMIN"', () {
        expect(UserRoleType.admin.value, 'ADMIN');
      });

      test('user.value returns "USER"', () {
        expect(UserRoleType.user.value, 'USER');
      });

      test('block.value returns "BLOCK"', () {
        expect(UserRoleType.block.value, 'BLOCK');
      });

      test('guest.value returns "GUEST"', () {
        expect(UserRoleType.guest.value, 'GUEST');
      });
    });

    group('fromString', () {
      test('parses "ADMIN"', () {
        expect(
            UserRoleTypeValue.fromString('ADMIN'), UserRoleType.admin);
      });

      test('parses "USER"', () {
        expect(
            UserRoleTypeValue.fromString('USER'), UserRoleType.user);
      });

      test('parses "BLOCK"', () {
        expect(
            UserRoleTypeValue.fromString('BLOCK'), UserRoleType.block);
      });

      test('parses "GUEST"', () {
        expect(
            UserRoleTypeValue.fromString('GUEST'), UserRoleType.guest);
      });

      test('parses lowercase "admin" (case-insensitive)', () {
        expect(
            UserRoleTypeValue.fromString('admin'), UserRoleType.admin);
      });

      test('parses mixed-case "User"', () {
        expect(
            UserRoleTypeValue.fromString('User'), UserRoleType.user);
      });

      test('returns none for null', () {
        expect(UserRoleTypeValue.fromString(null), UserRoleType.none);
      });

      test('returns none for unknown string', () {
        expect(
            UserRoleTypeValue.fromString('moderator'), UserRoleType.none);
      });
    });
  });
}
