import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:omi/backend/preferences.dart';

/// Tests for the DEV_BYPASS_AUTH escape-hatch.
///
/// We can't construct an AuthenticationProvider in a pure unit test
/// (it touches FirebaseAuth in its ctor), and AuthService.isSignedIn()
/// also calls FirebaseAuth.instance which throws without Firebase init.
///
/// What we CAN test deterministically here is the contract that
/// AuthenticationProvider.onDevBypassSignIn must honour when it
/// writes the stub session, and the token-shape rules that the
/// runtime gates depend on:
///
///   - token >= 32 chars (stub backend "Token too short" gate)
///   - token startsWith 'dev-bypass-' (isSignedIn() marker)
///   - uid / email / givenName persisted in SharedPreferences so
///     wrapper.dart::NameWidget can read them through the safe* helpers
void main() {
  group('DEV_BYPASS_AUTH contract', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferencesUtil.init();
    });

    test('a valid dev-bypass token satisfies the stub backend length rule', () {
      const token = 'dev-bypass-token-no-firebase-0123456789abcdef';
      expect(token.length >= 32, isTrue, reason: 'stub rejects <32 chars');
      expect(token.startsWith('dev-bypass-'), isTrue,
          reason: 'isSignedIn() marker');
    });

    test('stub-session round-trip through SharedPreferences', () {
      // Simulate the writes onDevBypassSignIn performs.
      final prefs = SharedPreferencesUtil();
      const fakeUid = 'dev-stub-user-deadbeef';
      const fakeToken = 'dev-bypass-token-no-firebase-aaaabbbbccccdddd';
      final expiry = DateTime.now()
          .add(const Duration(days: 365))
          .millisecondsSinceEpoch;

      prefs.uid = fakeUid;
      prefs.email = 'dev@atwenture.local';
      prefs.givenName = 'Dev';
      prefs.authToken = fakeToken;
      prefs.tokenExpirationTime = expiry;

      // Read-back: these are exactly what the safeUser* helpers read.
      expect(prefs.uid, fakeUid);
      expect(prefs.email, 'dev@atwenture.local');
      expect(prefs.givenName, 'Dev');
      expect(prefs.authToken, fakeToken);
      expect(prefs.tokenExpirationTime, expiry);
      expect(prefs.tokenExpirationTime,
          greaterThan(DateTime.now().millisecondsSinceEpoch));
    });

    test('non-bypass token does NOT satisfy isSignedIn marker', () {
      // Sanity-check: the marker rule is specific enough that real
      // Firebase ID-tokens (which never start with 'dev-bypass-')
      // won't be mistaken for a bypass session.
      const realLooking =
          'eyJhbGciOiJSUzI1NiIsImtpZCI6IjE...veryLongFirebaseIdToken';
      expect(realLooking.startsWith('dev-bypass-'), isFalse);
    });
  });
}
