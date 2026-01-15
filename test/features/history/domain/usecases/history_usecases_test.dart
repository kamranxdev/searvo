import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';
import 'package:searvo/features/history/domain/usecases/get_all_conversations.dart';
import 'package:searvo/features/history/domain/usecases/get_conversation_by_id.dart';
import 'package:searvo/features/history/domain/usecases/delete_conversation.dart';
import 'package:searvo/features/history/domain/usecases/toggle_pin_conversation.dart';
import 'package:searvo/features/history/domain/usecases/search_conversations.dart';

// Mock ConversationRepository
class MockConversationRepository implements ConversationRepository {
  bool shouldSucceed = true;
  List<Conversation> mockConversations = [];
  Map<String, List<Conversation>> mockGroupedConversations = {};
  Failure mockFailure = const CacheFailure();

  @override
  Future<Either<Failure, List<Conversation>>> getAllConversations() async {
    if (shouldSucceed) {
      return Right(mockConversations);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Map<String, List<Conversation>>>> getGroupedConversations() async {
    if (shouldSucceed) {
      return Right(mockGroupedConversations);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Conversation>> getConversationById(String conversationId) async {
    if (shouldSucceed) {
      try {
        final conv = mockConversations.firstWhere((c) => c.conversationId == conversationId);
        return Right(conv);
      } catch (e) {
        return const Left(NotFoundFailure());
      }
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query) async {
    if (shouldSucceed) {
      final results = mockConversations.where(
        (c) => c.title.toLowerCase().contains(query.toLowerCase()) ||
               (c.lastQuery?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
      return Right(results);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Conversation>> saveConversation({
    required String conversationId,
    required String title,
    required List<dynamic> messageBranches,
    List<String>? tags,
  }) async {
    if (shouldSucceed) {
      final now = DateTime.now();
      final conversation = Conversation(
        conversationId: conversationId,
        title: title,
        createdAt: now,
        updatedAt: now,
        tags: tags ?? [],
      );
      mockConversations.add(conversation);
      return Right(conversation);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Conversation>> updateConversation({
    required String conversationId,
    String? title,
    List<dynamic>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  }) async {
    if (shouldSucceed) {
      final index = mockConversations.indexWhere((c) => c.conversationId == conversationId);
      if (index != -1) {
        final updated = mockConversations[index].copyWith(
          title: title,
          isPinned: isPinned,
          tags: tags,
        );
        mockConversations[index] = updated;
        return Right(updated);
      }
      return const Left(NotFoundFailure());
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Unit>> deleteConversation(String conversationId) async {
    if (shouldSucceed) {
      mockConversations.removeWhere((c) => c.conversationId == conversationId);
      return const Right(unit);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Unit>> togglePin(String conversationId) async {
    if (shouldSucceed) {
      final index = mockConversations.indexWhere((c) => c.conversationId == conversationId);
      if (index != -1) {
        final conv = mockConversations[index];
        mockConversations[index] = conv.copyWith(isPinned: !conv.isPinned);
        return const Right(unit);
      }
      return const Left(NotFoundFailure());
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Unit>> clearAllConversations() async {
    if (shouldSucceed) {
      mockConversations.clear();
      return const Right(unit);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, List<Conversation>>> getPinnedConversations() async {
    if (shouldSucceed) {
      final pinned = mockConversations.where((c) => c.isPinned).toList();
      return Right(pinned);
    }
    return Left(mockFailure);
  }
}

void main() {
  late MockConversationRepository mockRepository;
  final now = DateTime.now();

  final testConversations = [
    Conversation(
      conversationId: 'conv-1',
      title: 'First Conversation',
      createdAt: now,
      updatedAt: now,
      lastQuery: 'flutter development',
    ),
    Conversation(
      conversationId: 'conv-2',
      title: 'Second Conversation',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      isPinned: true,
    ),
    Conversation(
      conversationId: 'conv-3',
      title: 'Third Conversation',
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
  ];

  setUp(() {
    mockRepository = MockConversationRepository();
    mockRepository.mockConversations = List.from(testConversations);
    mockRepository.shouldSucceed = true;
  });

  group('GetAllConversations UseCase Tests', () {
    late GetAllConversations useCase;

    setUp(() {
      useCase = GetAllConversations(mockRepository);
    });

    test('should return list of conversations when successful', () async {
      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) {
          expect(conversations.length, 3);
          expect(conversations[0].conversationId, 'conv-1');
        },
      );
    });

    test('should return failure when repository fails', () async {
      mockRepository.shouldSucceed = false;

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (conversations) => fail('Should not return conversations'),
      );
    });
  });

  group('GetConversationById UseCase Tests', () {
    late GetConversationById useCase;

    setUp(() {
      useCase = GetConversationById(mockRepository);
    });

    test('should return conversation when found', () async {
      final result = await useCase('conv-1');

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversation) {
          expect(conversation.conversationId, 'conv-1');
          expect(conversation.title, 'First Conversation');
        },
      );
    });

    test('should return NotFoundFailure when conversation not found', () async {
      final result = await useCase('non-existent');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (conversation) => fail('Should not return conversation'),
      );
    });
  });

  group('DeleteConversation UseCase Tests', () {
    late DeleteConversation useCase;

    setUp(() {
      useCase = DeleteConversation(mockRepository);
    });

    test('should delete conversation and return unit', () async {
      expect(mockRepository.mockConversations.length, 3);

      final result = await useCase(const DeleteConversationParams(conversationId: 'conv-1'));

      expect(result.isRight(), isTrue);
      expect(mockRepository.mockConversations.length, 2);
      expect(
        mockRepository.mockConversations.any((c) => c.conversationId == 'conv-1'),
        isFalse,
      );
    });

    test('should return failure when deletion fails', () async {
      mockRepository.shouldSucceed = false;

      final result = await useCase(const DeleteConversationParams(conversationId: 'conv-1'));

      expect(result.isLeft(), isTrue);
    });
  });

  group('TogglePinConversation UseCase Tests', () {
    late TogglePinConversation useCase;

    setUp(() {
      useCase = TogglePinConversation(mockRepository);
    });

    test('should toggle pin status from false to true', () async {
      final conv = mockRepository.mockConversations.firstWhere(
        (c) => c.conversationId == 'conv-1',
      );
      expect(conv.isPinned, false);

      final result = await useCase(const TogglePinConversationParams(conversationId: 'conv-1'));

      expect(result.isRight(), isTrue);
      final updated = mockRepository.mockConversations.firstWhere(
        (c) => c.conversationId == 'conv-1',
      );
      expect(updated.isPinned, true);
    });

    test('should toggle pin status from true to false', () async {
      final conv = mockRepository.mockConversations.firstWhere(
        (c) => c.conversationId == 'conv-2',
      );
      expect(conv.isPinned, true);

      final result = await useCase(const TogglePinConversationParams(conversationId: 'conv-2'));

      expect(result.isRight(), isTrue);
      final updated = mockRepository.mockConversations.firstWhere(
        (c) => c.conversationId == 'conv-2',
      );
      expect(updated.isPinned, false);
    });

    test('should return failure for non-existent conversation', () async {
      final result = await useCase(const TogglePinConversationParams(conversationId: 'non-existent'));

      expect(result.isLeft(), isTrue);
    });
  });

  group('SearchConversations UseCase Tests', () {
    late SearchConversations useCase;

    setUp(() {
      useCase = SearchConversations(mockRepository);
    });

    test('should return matching conversations by title', () async {
      final result = await useCase(const SearchConversationsParams(query: 'First'));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) {
          expect(conversations.length, 1);
          expect(conversations[0].title, 'First Conversation');
        },
      );
    });

    test('should return matching conversations by lastQuery', () async {
      final result = await useCase(const SearchConversationsParams(query: 'flutter'));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) {
          expect(conversations.length, 1);
          expect(conversations[0].conversationId, 'conv-1');
        },
      );
    });

    test('should return empty list when no matches', () async {
      final result = await useCase(const SearchConversationsParams(query: 'xyz123'));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) => expect(conversations, isEmpty),
      );
    });

    test('should be case insensitive', () async {
      final result = await useCase(const SearchConversationsParams(query: 'FIRST'));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) => expect(conversations.length, 1),
      );
    });
  });

  group('ConversationRepository Additional Tests', () {
    test('getPinnedConversations should return only pinned', () async {
      final result = await mockRepository.getPinnedConversations();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversations) {
          expect(conversations.length, 1);
          expect(conversations[0].isPinned, true);
        },
      );
    });

    test('clearAllConversations should remove all', () async {
      expect(mockRepository.mockConversations.length, 3);

      final result = await mockRepository.clearAllConversations();

      expect(result.isRight(), isTrue);
      expect(mockRepository.mockConversations, isEmpty);
    });

    test('saveConversation should add new conversation', () async {
      final result = await mockRepository.saveConversation(
        conversationId: 'conv-new',
        title: 'New Conversation',
        messageBranches: [],
        tags: ['new'],
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversation) {
          expect(conversation.conversationId, 'conv-new');
          expect(conversation.title, 'New Conversation');
          expect(conversation.tags, ['new']);
        },
      );
      expect(mockRepository.mockConversations.length, 4);
    });

    test('updateConversation should modify existing conversation', () async {
      final result = await mockRepository.updateConversation(
        conversationId: 'conv-1',
        title: 'Updated Title',
        isPinned: true,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (conversation) {
          expect(conversation.title, 'Updated Title');
          expect(conversation.isPinned, true);
        },
      );
    });
  });
}
