import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/features/search/domain/entities/message_branch.dart';
import 'package:searvo/features/search/domain/entities/message_branch_manager.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';

void main() {
  group('MessageBranch Tests', () {
    late MessageData testMessage;
    late DateTime testCreatedAt;

    setUp(() {
      testMessage = MessageData(query: 'Test query', answer: 'Test answer');
      testCreatedAt = DateTime(2024, 1, 15, 10, 30);
    });

    test('should create MessageBranch with required fields', () {
      final branch = MessageBranch(
        id: 'branch-1',
        message: testMessage,
        createdAt: testCreatedAt,
      );

      expect(branch.id, 'branch-1');
      expect(branch.message.query, 'Test query');
      expect(branch.message.answer, 'Test answer');
      expect(branch.createdAt, testCreatedAt);
      expect(branch.parentBranchId, isNull);
    });

    test('should create MessageBranch with parentBranchId', () {
      final branch = MessageBranch(
        id: 'branch-2',
        message: testMessage,
        createdAt: testCreatedAt,
        parentBranchId: 'parent-branch-1',
      );

      expect(branch.parentBranchId, 'parent-branch-1');
    });

    group('copyWith', () {
      late MessageBranch originalBranch;

      setUp(() {
        originalBranch = MessageBranch(
          id: 'original-id',
          message: testMessage,
          createdAt: testCreatedAt,
          parentBranchId: 'parent-id',
        );
      });

      test('should return new MessageBranch with updated id', () {
        final updated = originalBranch.copyWith(id: 'new-id');
        expect(updated.id, 'new-id');
        expect(updated.message, originalBranch.message);
      });

      test('should return new MessageBranch with updated message', () {
        final newMessage = MessageData(
          query: 'New query',
          answer: 'New answer',
        );
        final updated = originalBranch.copyWith(message: newMessage);
        expect(updated.message.query, 'New query');
        expect(updated.id, originalBranch.id);
      });

      test('should return new MessageBranch with updated createdAt', () {
        final newDate = DateTime(2025, 6, 1);
        final updated = originalBranch.copyWith(createdAt: newDate);
        expect(updated.createdAt, newDate);
      });

      test('should return new MessageBranch with updated parentBranchId', () {
        final updated = originalBranch.copyWith(parentBranchId: 'new-parent');
        expect(updated.parentBranchId, 'new-parent');
      });

      test('should keep original values when no updates provided', () {
        final updated = originalBranch.copyWith();
        expect(updated.id, originalBranch.id);
        expect(updated.message.query, originalBranch.message.query);
        expect(updated.createdAt, originalBranch.createdAt);
        expect(updated.parentBranchId, originalBranch.parentBranchId);
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        final branch = MessageBranch(
          id: 'branch-1',
          message: MessageData(
            query: 'Test query',
            answer: 'Test answer',
            relatedQuestions: ['Q1', 'Q2'],
            sources: [],
            attachments: [],
          ),
          createdAt: testCreatedAt,
          parentBranchId: 'parent-1',
        );

        final json = branch.toJson();

        expect(json['id'], 'branch-1');
        expect(json['message']['query'], 'Test query');
        expect(json['message']['answer'], 'Test answer');
        expect(json['message']['relatedQuestions'], ['Q1', 'Q2']);
        expect(json['parentBranchId'], 'parent-1');
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final branch = MessageBranch(
          id: 'branch-1',
          message: testMessage,
          createdAt: testCreatedAt,
        );

        final str = branch.toString();
        expect(str, contains('branch-1'));
        expect(str, contains('Test query'));
      });
    });
  });

  group('MessageBranchManager Tests', () {
    late MessageBranch branch1;
    late MessageBranch branch2;
    late MessageBranch branch3;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      branch1 = MessageBranch(
        id: 'branch-1',
        message: MessageData(query: 'Query 1', answer: 'Answer 1'),
        createdAt: testDate,
      );
      branch2 = MessageBranch(
        id: 'branch-2',
        message: MessageData(query: 'Query 2', answer: 'Answer 2'),
        createdAt: testDate.add(const Duration(minutes: 1)),
      );
      branch3 = MessageBranch(
        id: 'branch-3',
        message: MessageData(query: 'Query 3', answer: 'Answer 3'),
        createdAt: testDate.add(const Duration(minutes: 2)),
      );
    });

    test('should throw assertion error when branches list is empty', () {
      expect(
        () => MessageBranchManager(branches: []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should create with single branch', () {
      final manager = MessageBranchManager(branches: [branch1]);
      expect(manager.branches.length, 1);
      expect(manager.currentBranchIndex, 0);
    });

    test('should create with custom initial index', () {
      final manager = MessageBranchManager(
        branches: [branch1, branch2, branch3],
        currentBranchIndex: 1,
      );
      expect(manager.currentBranchIndex, 1);
      expect(manager.currentBranch.id, 'branch-2');
    });

    group('currentBranch', () {
      test('should return the current branch', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        expect(manager.currentBranch, branch1);
      });

      test('should return correct branch after navigation', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        manager.goToNextBranch();
        expect(manager.currentBranch, branch2);
      });
    });

    group('currentMessage', () {
      test('should return message from current branch', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        expect(manager.currentMessage.query, 'Query 1');
      });
    });

    group('hasPreviousBranch', () {
      test('should return false at first branch', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        expect(manager.hasPreviousBranch, false);
      });

      test('should return true when not at first branch', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2],
          currentBranchIndex: 1,
        );
        expect(manager.hasPreviousBranch, true);
      });
    });

    group('hasNextBranch', () {
      test('should return true when not at last branch', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        expect(manager.hasNextBranch, true);
      });

      test('should return false at last branch', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2],
          currentBranchIndex: 1,
        );
        expect(manager.hasNextBranch, false);
      });
    });

    group('totalBranches', () {
      test('should return correct count', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
        );
        expect(manager.totalBranches, 3);
      });
    });

    group('currentBranchNumber', () {
      test('should return 1-indexed branch number', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        expect(manager.currentBranchNumber, 1);
        manager.goToNextBranch();
        expect(manager.currentBranchNumber, 2);
      });
    });

    group('goToPreviousBranch', () {
      test('should navigate to previous branch', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
          currentBranchIndex: 2,
        );
        manager.goToPreviousBranch();
        expect(manager.currentBranchIndex, 1);
      });

      test('should not go below 0', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        manager.goToPreviousBranch();
        expect(manager.currentBranchIndex, 0);
      });
    });

    group('goToNextBranch', () {
      test('should navigate to next branch', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
        );
        manager.goToNextBranch();
        expect(manager.currentBranchIndex, 1);
      });

      test('should not exceed last index', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2],
          currentBranchIndex: 1,
        );
        manager.goToNextBranch();
        expect(manager.currentBranchIndex, 1);
      });
    });

    group('goToBranch', () {
      test('should navigate to specific branch', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
        );
        manager.goToBranch(2);
        expect(manager.currentBranchIndex, 2);
      });

      test('should not navigate to negative index', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        manager.goToBranch(-1);
        expect(manager.currentBranchIndex, 0);
      });

      test('should not navigate to out of bounds index', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        manager.goToBranch(10);
        expect(manager.currentBranchIndex, 0);
      });
    });

    group('addBranch', () {
      test('should add new branch and set as current', () {
        final manager = MessageBranchManager(branches: [branch1]);
        manager.addBranch(branch2);

        expect(manager.totalBranches, 2);
        expect(manager.currentBranchIndex, 1);
        expect(manager.currentBranch.id, 'branch-2');
      });
    });

    group('updateCurrentBranch', () {
      test('should update current branch message', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        final newMessage = MessageData(
          query: 'Updated',
          answer: 'Updated answer',
        );

        manager.updateCurrentBranch(newMessage);

        expect(manager.currentMessage.query, 'Updated');
        expect(manager.currentMessage.answer, 'Updated answer');
      });
    });

    group('getBranchById', () {
      test('should return branch when found', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
        );
        final found = manager.getBranchById('branch-2');

        expect(found, isNotNull);
        expect(found!.id, 'branch-2');
      });

      test('should return null when not found', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);
        final found = manager.getBranchById('non-existent');

        expect(found, isNull);
      });
    });

    group('removeBranch', () {
      test('should remove branch at index', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
        );
        final removed = manager.removeBranch(1);

        expect(removed, true);
        expect(manager.totalBranches, 2);
        expect(manager.branches[1].id, 'branch-3');
      });

      test('should not remove if only one branch', () {
        final manager = MessageBranchManager(branches: [branch1]);
        final removed = manager.removeBranch(0);

        expect(removed, false);
        expect(manager.totalBranches, 1);
      });

      test('should not remove at invalid index', () {
        final manager = MessageBranchManager(branches: [branch1, branch2]);

        expect(manager.removeBranch(-1), false);
        expect(manager.removeBranch(5), false);
      });

      test('should adjust currentBranchIndex when removing before current', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
          currentBranchIndex: 2,
        );
        manager.removeBranch(0);

        expect(manager.currentBranchIndex, 1);
      });

      test('should adjust currentBranchIndex when current exceeds length', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2],
          currentBranchIndex: 1,
        );
        manager.removeBranch(1);

        expect(manager.currentBranchIndex, 0);
      });
    });

    group('Navigation sequence', () {
      test('should correctly navigate through all branches', () {
        final manager = MessageBranchManager(
          branches: [branch1, branch2, branch3],
        );

        expect(manager.currentBranchNumber, 1);
        expect(manager.hasPreviousBranch, false);
        expect(manager.hasNextBranch, true);

        manager.goToNextBranch();
        expect(manager.currentBranchNumber, 2);
        expect(manager.hasPreviousBranch, true);
        expect(manager.hasNextBranch, true);

        manager.goToNextBranch();
        expect(manager.currentBranchNumber, 3);
        expect(manager.hasPreviousBranch, true);
        expect(manager.hasNextBranch, false);

        manager.goToPreviousBranch();
        manager.goToPreviousBranch();
        expect(manager.currentBranchNumber, 1);
      });
    });
  });
}
