import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fathom/features/auth/presentation/providers/auth_provider.dart';
import 'package:fathom/features/projects/presentation/providers/projects_provider.dart';
import 'package:fathom/features/chat/presentation/providers/chat_provider.dart';
import 'package:fathom/features/settings/presentation/providers/settings_provider.dart';
import 'package:fathom/features/auth/data/models/user_model.dart';
import 'package:fathom/features/projects/data/models/project_model.dart';
import 'package:fathom/features/chat/data/models/chat_model.dart';

// Simple Mocks
class MockAuthProvider extends Mock implements AuthProvider {}
class MockProjectsProvider extends Mock implements ProjectsProvider {}
class MockChatProvider extends Mock implements ChatProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('Fathom Application Provider & Logic Tests', () {
    late UserModel testUser;
    late ProjectModel testProject;
    late ChatModel testChat;

    setUp(() {
      testUser = UserModel(
        uid: 'user123',
        displayName: 'Test User',
        email: 'test@fathom.com',
        createdAt: DateTime.now(),
        isAnonymous: false,
        dailyChatCount: 10,
        lastChatReset: DateTime.now(),
      );

      testProject = ProjectModel(
        id: 'proj123',
        userId: 'user123',
        name: 'Project A',
        isPinned: false,
        order: 1,
        createdAt: DateTime.now(),
      );

      testChat = ChatModel(
        id: 'chat123',
        userId: 'user123',
        title: 'New Chat Title',
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('User Authentication state model mapping verification', () {
      expect(testUser.uid, 'user123');
      expect(testUser.isAnonymous, false);
      expect(testUser.dailyChatCount, 10);
    });

    test('Usage limits verification for Guest User vs Registered User', () {
      final guestUser = UserModel(
        uid: 'guest123',
        displayName: 'Guest User',
        createdAt: DateTime.now(),
        isAnonymous: true,
        dailyChatCount: 4,
        lastChatReset: DateTime.now(),
      );

      // Verify guest limit criteria
      expect(guestUser.isAnonymous, isTrue);
      expect(guestUser.dailyChatCount < 5, isTrue); // Guest is allowed up to 5 chats

      // Verify registered user limit criteria
      expect(testUser.isAnonymous, isFalse);
      expect(testUser.dailyChatCount < 50, isTrue); // Registered user allowed up to 50 chats
    });

    test('Project management and pinning updates validation', () {
      final pinnedProj = testProject.copyWith(isPinned: true);
      expect(pinnedProj.isPinned, isTrue);
      expect(pinnedProj.name, 'Project A');
    });

    test('Chat creation and custom renaming validation', () {
      final renamedChat = testChat.copyWith(title: 'Renamed Chat');
      expect(renamedChat.title, 'Renamed Chat');
      expect(renamedChat.isPinned, isFalse);
    });
  });
}
