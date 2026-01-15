class ToolWidgetData {
  final String id;
  final String toolId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ToolWidgetData({
    required this.id,
    required this.toolId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ToolWidgetData copyWith({
    String? id,
    String? toolId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return ToolWidgetData(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
