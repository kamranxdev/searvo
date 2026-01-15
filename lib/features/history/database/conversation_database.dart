import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'conversation_database.g.dart';

/// Conversations table
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get conversationId => text().unique()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  TextColumn get lastQuery => text().nullable()();
  TextColumn get lastAnswer => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
}

/// Messages table (related to conversations)
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get messageId => text()();
  TextColumn get query => text()();
  TextColumn get answer => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isFallback => boolean().withDefault(const Constant(false))();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get branchId => text().nullable()();
  TextColumn get parentBranchId => text().nullable()();
  IntColumn get branchIndex => integer().withDefault(const Constant(0))();
  IntColumn get totalBranches => integer().withDefault(const Constant(1))();
  TextColumn get relatedQuestions => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get images => text().withDefault(const Constant('[]'))(); // JSON array
}

/// Sources table (related to messages)
class Sources extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageId => integer().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get thumbnail => text()();
  TextColumn get favicon => text().nullable()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get domain => text()();
  DateTimeColumn get publishedDate => dateTime().nullable()();
  TextColumn get source => text().nullable()();
}

/// Videos table (related to messages)
class Videos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageId => integer().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get thumbnail => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get domain => text()();
  TextColumn get duration => text().nullable()();
  DateTimeColumn get publishedDate => dateTime().nullable()();
  IntColumn get views => integer().nullable()();
}

/// Attachments table (related to messages)
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageId => integer().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get attachmentId => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  TextColumn get type => text()();
  IntColumn get size => integer()();
  DateTimeColumn get uploadedAt => dateTime()();
  TextColumn get extractedText => text().nullable()();
}

/// Main database class
@DriftDatabase(tables: [Conversations, Messages, Sources, Videos, Attachments])
class ConversationDatabase extends _$ConversationDatabase {
  ConversationDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// Create database connection
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'conversation_database',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ==================== Conversation Operations ====================

  /// Get all conversations sorted by date
  Future<List<Conversation>> getAllConversations({bool pinnedFirst = true}) async {
    final query = select(conversations);
    if (pinnedFirst) {
      query.orderBy([
        (c) => OrderingTerm(expression: c.isPinned, mode: OrderingMode.desc),
        (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc),
      ]);
    } else {
      query.orderBy([(c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc)]);
    }
    return query.get();
  }

  /// Get conversation by conversation ID
  Future<Conversation?> getConversationByConversationId(String conversationId) async {
    final query = select(conversations)..where((c) => c.conversationId.equals(conversationId));
    return query.getSingleOrNull();
  }

  /// Insert a new conversation
  Future<int> insertConversation(ConversationsCompanion conversation) async {
    return into(conversations).insert(conversation);
  }

  /// Update a conversation
  Future<bool> updateConversation(Conversation conversation) async {
    return update(conversations).replace(conversation);
  }

  /// Delete a conversation by conversation ID
  Future<int> deleteConversationByConversationId(String conversationId) async {
    return (delete(conversations)..where((c) => c.conversationId.equals(conversationId))).go();
  }

  /// Delete all conversations
  Future<int> deleteAllConversations() async {
    return delete(conversations).go();
  }

  /// Get pinned conversations
  Future<List<Conversation>> getPinnedConversations() async {
    final query = select(conversations)
      ..where((c) => c.isPinned.equals(true))
      ..orderBy([(c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    final countExp = conversations.id.count();
    final query = selectOnly(conversations)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Search conversations by query
  Future<List<Conversation>> searchConversations(String query) async {
    final lowerQuery = query.toLowerCase();
    return (select(conversations)
          ..where((c) =>
              c.title.lower().like('%$lowerQuery%') |
              c.lastQuery.lower().like('%$lowerQuery%') |
              c.lastAnswer.lower().like('%$lowerQuery%')))
        .get();
  }

  // ==================== Message Operations ====================

  /// Get all messages for a conversation
  Future<List<Message>> getMessagesForConversation(int conversationId) async {
    final query = select(messages)
      ..where((m) => m.conversationId.equals(conversationId))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]);
    return query.get();
  }

  /// Insert a new message
  Future<int> insertMessage(MessagesCompanion message) async {
    return into(messages).insert(message);
  }

  /// Delete all messages for a conversation
  Future<int> deleteMessagesForConversation(int conversationId) async {
    return (delete(messages)..where((m) => m.conversationId.equals(conversationId))).go();
  }

  // ==================== Source Operations ====================

  /// Get all sources for a message
  Future<List<Source>> getSourcesForMessage(int messageId) async {
    final query = select(sources)..where((s) => s.messageId.equals(messageId));
    return query.get();
  }

  /// Insert a new source
  Future<int> insertSource(SourcesCompanion source) async {
    return into(sources).insert(source);
  }

  /// Insert multiple sources
  Future<void> insertSources(List<SourcesCompanion> sourceList) async {
    await batch((batch) {
      batch.insertAll(sources, sourceList);
    });
  }

  // ==================== Video Operations ====================

  /// Get all videos for a message
  Future<List<Video>> getVideosForMessage(int messageId) async {
    final query = select(videos)..where((v) => v.messageId.equals(messageId));
    return query.get();
  }

  /// Insert a new video
  Future<int> insertVideo(VideosCompanion video) async {
    return into(videos).insert(video);
  }

  /// Insert multiple videos
  Future<void> insertVideos(List<VideosCompanion> videoList) async {
    await batch((batch) {
      batch.insertAll(videos, videoList);
    });
  }

  // ==================== Attachment Operations ====================

  /// Get all attachments for a message
  Future<List<Attachment>> getAttachmentsForMessage(int messageId) async {
    final query = select(attachments)..where((a) => a.messageId.equals(messageId));
    return query.get();
  }

  /// Insert a new attachment
  Future<int> insertAttachment(AttachmentsCompanion attachment) async {
    return into(attachments).insert(attachment);
  }

  /// Insert multiple attachments
  Future<void> insertAttachments(List<AttachmentsCompanion> attachmentList) async {
    await batch((batch) {
      batch.insertAll(attachments, attachmentList);
    });
  }
}
