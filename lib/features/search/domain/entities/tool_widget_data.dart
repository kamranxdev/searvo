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

  factory ToolWidgetData.fromMap(Map<String, dynamic> map) {
    return ToolWidgetData(
      id: map['id']?.toString() ?? '',
      toolId: map['toolId']?.toString() ?? '',
      data: map['data'] is Map ? Map<String, dynamic>.from(map['data']) : {},
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toolId': toolId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
