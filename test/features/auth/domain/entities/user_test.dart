import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/auth/domain/entities/user.dart';

void main() {
  group('User Entity Tests', () {
    const testUser = User(
      uid: 'test-uid-123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isAnonymous: false,
      createdAt: null,
      lastSignInAt: null,
    );

    group('Constructor', () {
      test('should create User with required uid', () {
        const user = User(uid: 'uid-123');
        expect(user.uid, 'uid-123');
        expect(user.email, isNull);
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
        expect(user.isAnonymous, false);
      });

      test('should create User with all properties', () {
        final now = DateTime.now();
        final user = User(
          uid: 'uid-123',
          email: 'user@email.com',
          displayName: 'John Doe',
          photoUrl: 'https://photo.url',
          isAnonymous: true,
          createdAt: now,
          lastSignInAt: now,
        );

        expect(user.uid, 'uid-123');
        expect(user.email, 'user@email.com');
        expect(user.displayName, 'John Doe');
        expect(user.photoUrl, 'https://photo.url');
        expect(user.isAnonymous, true);
        expect(user.createdAt, now);
        expect(user.lastSignInAt, now);
      });

      test('should have isAnonymous default to false', () {
        const user = User(uid: 'uid');
        expect(user.isAnonymous, false);
      });
    });

    group('copyWith', () {
      test('should return new User with updated uid', () {
        final updatedUser = testUser.copyWith(uid: 'new-uid');
        expect(updatedUser.uid, 'new-uid');
        expect(updatedUser.email, testUser.email);
        expect(updatedUser.displayName, testUser.displayName);
      });

      test('should return new User with updated email', () {
        final updatedUser = testUser.copyWith(email: 'new@email.com');
        expect(updatedUser.email, 'new@email.com');
        expect(updatedUser.uid, testUser.uid);
      });

      test('should return new User with updated displayName', () {
        final updatedUser = testUser.copyWith(displayName: 'New Name');
        expect(updatedUser.displayName, 'New Name');
      });

      test('should return new User with updated photoUrl', () {
        final updatedUser = testUser.copyWith(photoUrl: 'https://new.photo');
        expect(updatedUser.photoUrl, 'https://new.photo');
      });

      test('should return new User with updated isAnonymous', () {
        final updatedUser = testUser.copyWith(isAnonymous: true);
        expect(updatedUser.isAnonymous, true);
      });

      test('should return new User with updated createdAt', () {
        final newDate = DateTime(2024, 1, 1);
        final updatedUser = testUser.copyWith(createdAt: newDate);
        expect(updatedUser.createdAt, newDate);
      });

      test('should return new User with updated lastSignInAt', () {
        final newDate = DateTime(2024, 6, 15);
        final updatedUser = testUser.copyWith(lastSignInAt: newDate);
        expect(updatedUser.lastSignInAt, newDate);
      });

      test('should keep original values when no updates provided', () {
        final updatedUser = testUser.copyWith();
        expect(updatedUser.uid, testUser.uid);
        expect(updatedUser.email, testUser.email);
        expect(updatedUser.displayName, testUser.displayName);
        expect(updatedUser.photoUrl, testUser.photoUrl);
        expect(updatedUser.isAnonymous, testUser.isAnonymous);
      });

      test('should update multiple fields at once', () {
        final updatedUser = testUser.copyWith(
          displayName: 'Updated Name',
          email: 'updated@email.com',
          isAnonymous: true,
        );
        expect(updatedUser.displayName, 'Updated Name');
        expect(updatedUser.email, 'updated@email.com');
        expect(updatedUser.isAnonymous, true);
        expect(updatedUser.uid, testUser.uid);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties match', () {
        const user1 = User(
          uid: 'uid-123',
          email: 'test@email.com',
          displayName: 'Test',
        );
        const user2 = User(
          uid: 'uid-123',
          email: 'test@email.com',
          displayName: 'Test',
        );
        expect(user1, equals(user2));
      });

      test('should not be equal when uid differs', () {
        const user1 = User(uid: 'uid-1');
        const user2 = User(uid: 'uid-2');
        expect(user1, isNot(equals(user2)));
      });

      test('should not be equal when email differs', () {
        const user1 = User(uid: 'uid', email: 'a@b.com');
        const user2 = User(uid: 'uid', email: 'c@d.com');
        expect(user1, isNot(equals(user2)));
      });

      test('should include all properties in props', () {
        final now = DateTime.now();
        final user = User(
          uid: 'uid',
          email: 'email',
          displayName: 'name',
          photoUrl: 'url',
          isAnonymous: true,
          createdAt: now,
          lastSignInAt: now,
        );
        expect(user.props, contains('uid'));
        expect(user.props, contains('email'));
        expect(user.props, contains('name'));
        expect(user.props, contains('url'));
        expect(user.props, contains(true));
        expect(user.props, contains(now));
      });
    });

    group('Edge Cases', () {
      test('should handle empty string uid', () {
        const user = User(uid: '');
        expect(user.uid, '');
      });

      test('should handle null optional fields', () {
        const user = User(uid: 'uid');
        expect(user.email, isNull);
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
        expect(user.createdAt, isNull);
        expect(user.lastSignInAt, isNull);
      });

      test('should handle empty string email', () {
        const user = User(uid: 'uid', email: '');
        expect(user.email, '');
      });
    });
  });
}
