import 'message_branch.dart';
import 'message_data.dart';

/// Manages multiple branches for a single message position in the conversation
class MessageBranchManager {
  final List<MessageBranch> branches;
  int currentBranchIndex;

  MessageBranchManager({required this.branches, this.currentBranchIndex = 0})
    : assert(branches.isNotEmpty, 'Branches list cannot be empty');

  /// Get the currently active branch
  MessageBranch get currentBranch => branches[currentBranchIndex];

  /// Get the message data from the current branch
  MessageData get currentMessage => currentBranch.message;

  /// Check if there's a previous branch to navigate to
  bool get hasPreviousBranch => currentBranchIndex > 0;

  /// Check if there's a next branch to navigate to
  bool get hasNextBranch => currentBranchIndex < branches.length - 1;

  /// Get total number of branches
  int get totalBranches => branches.length;

  /// Get current branch number (1-indexed for display)
  int get currentBranchNumber => currentBranchIndex + 1;

  /// Navigate to the previous branch
  void goToPreviousBranch() {
    if (hasPreviousBranch) {
      currentBranchIndex--;
    }
  }

  /// Navigate to the next branch
  void goToNextBranch() {
    if (hasNextBranch) {
      currentBranchIndex++;
    }
  }

  /// Navigate to a specific branch by index
  void goToBranch(int index) {
    if (index >= 0 && index < branches.length) {
      currentBranchIndex = index;
    }
  }

  /// Add a new branch and set it as current
  void addBranch(MessageBranch branch) {
    branches.add(branch);
    currentBranchIndex = branches.length - 1;
  }

  /// Update the current branch's message
  void updateCurrentBranch(MessageData newMessage) {
    branches[currentBranchIndex] = branches[currentBranchIndex].copyWith(
      message: newMessage,
    );
  }

  /// Get a branch by its ID
  MessageBranch? getBranchById(String id) {
    try {
      return branches.firstWhere((branch) => branch.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Remove a specific branch (cannot remove if it's the only one)
  bool removeBranch(int index) {
    if (branches.length <= 1 || index < 0 || index >= branches.length) {
      return false;
    }

    branches.removeAt(index);

    // Adjust current index if necessary
    if (currentBranchIndex >= branches.length) {
      currentBranchIndex = branches.length - 1;
    } else if (currentBranchIndex > index) {
      currentBranchIndex--;
    }

    return true;
  }

  /// Remove the current branch and switch to the previous one
  bool removeCurrentBranch() {
    if (branches.length <= 1) {
      return false;
    }

    final indexToRemove = currentBranchIndex;
    if (currentBranchIndex > 0) {
      currentBranchIndex--;
    }

    branches.removeAt(indexToRemove);
    return true;
  }

  /// Create a copy of this branch manager
  MessageBranchManager copyWith({
    List<MessageBranch>? branches,
    int? currentBranchIndex,
  }) {
    return MessageBranchManager(
      branches: branches ?? List<MessageBranch>.from(this.branches),
      currentBranchIndex: currentBranchIndex ?? this.currentBranchIndex,
    );
  }

  /// Get all branch IDs
  List<String> get branchIds => branches.map((b) => b.id).toList();

  /// Check if a branch with the given ID exists
  bool hasBranch(String id) {
    return branches.any((branch) => branch.id == id);
  }

  /// Get the index of a branch by its ID
  int? getBranchIndex(String id) {
    for (int i = 0; i < branches.length; i++) {
      if (branches[i].id == id) {
        return i;
      }
    }
    return null;
  }

  /// Get branches sorted by creation time
  List<MessageBranch> get branchesSortedByTime {
    final sorted = List<MessageBranch>.from(branches);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  /// Get the most recent branch
  MessageBranch get latestBranch {
    return branches.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  /// Get the oldest branch
  MessageBranch get oldestBranch {
    return branches.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);
  }

  Map<String, dynamic> toJson() {
    return {
      'branches': branches.map((b) => b.toJson()).toList(),
      'currentBranchIndex': currentBranchIndex,
    };
  }

  @override
  String toString() {
    return 'MessageBranchManager(totalBranches: $totalBranches, currentIndex: $currentBranchIndex)';
  }
}

/// Extension methods for easier branch navigation
extension BranchManagerNavigation on MessageBranchManager {
  /// Navigate to first branch
  void goToFirst() {
    currentBranchIndex = 0;
  }

  /// Navigate to last branch
  void goToLast() {
    currentBranchIndex = branches.length - 1;
  }

  /// Check if current branch is the first one
  bool get isAtFirst => currentBranchIndex == 0;

  /// Check if current branch is the last one
  bool get isAtLast => currentBranchIndex == branches.length - 1;

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (branches.length <= 1) return 1.0;
    return currentBranchIndex / (branches.length - 1);
  }
}
