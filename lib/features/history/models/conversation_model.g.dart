// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationModelAdapter extends TypeAdapter<ConversationModel> {
  @override
  final int typeId = 0;

  @override
  ConversationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationModel(
      id: fields[0] as int?,
      conversationId: fields[1] as String,
      title: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      isPinned: fields[5] as bool,
      messageCount: fields[6] as int,
      lastQuery: fields[7] as String?,
      lastAnswer: fields[8] as String?,
      tags: (fields[9] as List).cast<String>(),
      messages: (fields[10] as List).cast<ConversationMessageModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ConversationModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.messageCount)
      ..writeByte(7)
      ..write(obj.lastQuery)
      ..writeByte(8)
      ..write(obj.lastAnswer)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationMessageModelAdapter
    extends TypeAdapter<ConversationMessageModel> {
  @override
  final int typeId = 1;

  @override
  ConversationMessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationMessageModel(
      messageId: fields[0] as String,
      query: fields[1] as String,
      answer: fields[2] as String,
      sources: (fields[4] as List).cast<ConversationSourceModel>(),
      relatedQuestions: (fields[5] as List).cast<String>(),
      images: (fields[6] as List).cast<String>(),
      videos: (fields[7] as List).cast<ConversationVideoModel>(),
      attachments: (fields[8] as List).cast<ConversationAttachmentModel>(),
      isFallback: fields[9] as bool,
      errorMessage: fields[10] as String?,
      branchId: fields[11] as String?,
      parentBranchId: fields[12] as String?,
      branchIndex: fields[13] as int,
      totalBranches: fields[14] as int,
    )..timestamp = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ConversationMessageModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.query)
      ..writeByte(2)
      ..write(obj.answer)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.sources)
      ..writeByte(5)
      ..write(obj.relatedQuestions)
      ..writeByte(6)
      ..write(obj.images)
      ..writeByte(7)
      ..write(obj.videos)
      ..writeByte(8)
      ..write(obj.attachments)
      ..writeByte(9)
      ..write(obj.isFallback)
      ..writeByte(10)
      ..write(obj.errorMessage)
      ..writeByte(11)
      ..write(obj.branchId)
      ..writeByte(12)
      ..write(obj.parentBranchId)
      ..writeByte(13)
      ..write(obj.branchIndex)
      ..writeByte(14)
      ..write(obj.totalBranches);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationMessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationSourceModelAdapter
    extends TypeAdapter<ConversationSourceModel> {
  @override
  final int typeId = 2;

  @override
  ConversationSourceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationSourceModel(
      thumbnail: fields[0] as String,
      favicon: fields[1] as String?,
      url: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String,
      domain: fields[5] as String,
      publishedDate: fields[6] as DateTime?,
      source: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationSourceModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.thumbnail)
      ..writeByte(1)
      ..write(obj.favicon)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.domain)
      ..writeByte(6)
      ..write(obj.publishedDate)
      ..writeByte(7)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationSourceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationVideoModelAdapter
    extends TypeAdapter<ConversationVideoModel> {
  @override
  final int typeId = 3;

  @override
  ConversationVideoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationVideoModel(
      thumbnail: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      domain: fields[4] as String,
      duration: fields[5] as String?,
      publishedDate: fields[6] as DateTime?,
      views: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationVideoModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.thumbnail)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.domain)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.publishedDate)
      ..writeByte(7)
      ..write(obj.views);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationVideoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationAttachmentModelAdapter
    extends TypeAdapter<ConversationAttachmentModel> {
  @override
  final int typeId = 4;

  @override
  ConversationAttachmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationAttachmentModel(
      attachmentId: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      type: fields[3] as String,
      size: fields[4] as int,
      extractedText: fields[6] as String?,
    )..uploadedAt = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ConversationAttachmentModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.attachmentId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.size)
      ..writeByte(5)
      ..write(obj.uploadedAt)
      ..writeByte(6)
      ..write(obj.extractedText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAttachmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
