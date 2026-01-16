enum SearchStepStatus { pending, inProgress, completed, failed }

class SearchStep {
  final String id;
  final String title;
  final String? description;
  final SearchStepStatus status;
  final Duration duration;
  final DateTime timestamp;

  SearchStep({
    required this.id,
    required this.title,
    this.description,
    this.status = SearchStepStatus.pending,
    this.duration = Duration.zero,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  SearchStep copyWith({
    String? title,
    String? description,
    SearchStepStatus? status,
    Duration? duration,
  }) {
    return SearchStep(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      timestamp: timestamp,
    );
  }

  bool get isCompleted => status == SearchStepStatus.completed;
  bool get isFailed => status == SearchStepStatus.failed;
  bool get isInProgress => status == SearchStepStatus.inProgress;
  bool get isPending => status == SearchStepStatus.pending;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchStep.fromMap(Map<String, dynamic> map) {
    return SearchStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      status: SearchStepStatus.values[map['status'] ?? 0],
      duration: Duration(milliseconds: map['duration'] ?? 0),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : null,
    );
  }
}
