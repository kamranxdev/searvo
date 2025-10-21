import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';

/// Service for managing conversation sync with Firebase Firestore
/// Handles cloud storage operations for authenticated users
class ConversationCloudService {
  static final ConversationCloudService _instance = ConversationCloudService._internal();
  factory ConversationCloudService() => _instance;
  ConversationCloudService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  /// Get user's conversations collection reference
  CollectionReference<Map<String, dynamic>>? get _conversationsCollection {
    if (!isAuthenticated) return null;
    return _firestore.collection('users').doc(_userId).collection('conversations');
  }

  /// Sync a conversation to Firestore
  Future<void> syncConversation(ConversationModel conversation) async {
    if (!isAuthenticated || _conversationsCollection == null) {
      throw Exception('User not authenticated');
    }

    try {
      final conversationData = _conversationToMap(conversation);
      await _conversationsCollection!.doc(conversation.conversationId).set(conversationData);
    } catch (e) {
      print('❌ Failed to sync conversation to Firestore: $e');
      rethrow;
    }
  }

  /// Get all conversations from Firestore
  Future<List<ConversationModel>> getCloudConversations() async {
    if (!isAuthenticated || _conversationsCollection == null) {
      return [];
    }

    try {
      final snapshot = await _conversationsCollection!.get();
      return snapshot.docs.map((doc) => _mapToConversation(doc.data(), doc.id)).toList();
    } catch (e) {
      print('❌ Failed to get conversations from Firestore: $e');
      return [];
    }
  }

  /// Delete a conversation from Firestore
  Future<void> deleteCloudConversation(String conversationId) async {
    if (!isAuthenticated || _conversationsCollection == null) return;

    try {
      await _conversationsCollection!.doc(conversationId).delete();
    } catch (e) {
      print('❌ Failed to delete conversation from Firestore: $e');
      rethrow;
    }
  }

  /// Get last sync timestamp for a conversation
  Future<DateTime?> getLastSyncTimestamp(String conversationId) async {
    if (!isAuthenticated || _conversationsCollection == null) return null;

    try {
      final doc = await _conversationsCollection!.doc(conversationId).get();
      if (doc.exists) {
        final data = doc.data();
        final timestamp = data?['lastSyncedAt'];
        if (timestamp != null) {
          return (timestamp as Timestamp).toDate();
        }
      }
      return null;
    } catch (e) {
      print('❌ Failed to get sync timestamp: $e');
      return null;
    }
  }

  /// Convert ConversationModel to Firestore document map
  Map<String, dynamic> _conversationToMap(ConversationModel conversation) {
    return {
      'conversationId': conversation.conversationId,
      'title': conversation.title,
      'createdAt': Timestamp.fromDate(conversation.createdAt),
      'updatedAt': Timestamp.fromDate(conversation.updatedAt),
      'isPinned': conversation.isPinned,
      'messageCount': conversation.messageCount,
      'lastQuery': conversation.lastQuery,
      'lastAnswer': conversation.lastAnswer,
      'tags': conversation.tags,
      'lastSyncedAt': FieldValue.serverTimestamp(),
      'messages': conversation.messages.map((message) => {
        'messageId': message.messageId,
        'query': message.query,
        'answer': message.answer,
        'timestamp': Timestamp.fromDate(message.timestamp),
        'sources': message.sources.map((source) => {
          'thumbnail': source.thumbnail,
          'favicon': source.favicon,
          'url': source.url,
          'title': source.title,
          'description': source.description,
          'domain': source.domain,
          'publishedDate': source.publishedDate != null 
              ? Timestamp.fromDate(source.publishedDate!) 
              : null,
          'source': source.source,
        }).toList(),
        'relatedQuestions': message.relatedQuestions,
        'images': message.images,
        'videos': message.videos.map((video) => {
          'thumbnail': video.thumbnail,
          'url': video.url,
          'title': video.title,
          'description': video.description,
          'domain': video.domain,
          'duration': video.duration,
          'publishedDate': video.publishedDate != null 
              ? Timestamp.fromDate(video.publishedDate!) 
              : null,
          'views': video.views,
        }).toList(),
        'attachments': message.attachments.map((attachment) => {
          'attachmentId': attachment.attachmentId,
          'name': attachment.name,
          'path': attachment.path,
          'type': attachment.type,
          'size': attachment.size,
          'uploadedAt': Timestamp.fromDate(attachment.uploadedAt),
          'extractedText': attachment.extractedText,
        }).toList(),
        'isFallback': message.isFallback,
        'errorMessage': message.errorMessage,
        'branchId': message.branchId,
        'parentBranchId': message.parentBranchId,
        'branchIndex': message.branchIndex,
        'totalBranches': message.totalBranches,
      }).toList(),
    };
  }

  /// Convert Firestore document map to ConversationModel
  ConversationModel _mapToConversation(Map<String, dynamic> data, String conversationId) {
    return ConversationModel(
      id: null, // Cloud conversations don't use local IDs
      conversationId: data['conversationId'] ?? conversationId,
      title: data['title'] ?? 'Untitled Conversation',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: data['isPinned'] ?? false,
      messageCount: data['messageCount'] ?? 0,
      lastQuery: data['lastQuery'],
      lastAnswer: data['lastAnswer'],
      tags: List<String>.from(data['tags'] ?? []),
      messages: (data['messages'] as List<dynamic>?)?.map((messageData) {
        final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return ConversationMessageModel.create(
          messageId: messageData['messageId'] ?? '',
          query: messageData['query'] ?? '',
          answer: messageData['answer'] ?? '',
          timestamp: timestamp,
          sources: (messageData['sources'] as List<dynamic>?)?.map((sourceData) {
            final publishedDateRaw = sourceData['publishedDate'];
            final publishedDate = publishedDateRaw is Timestamp 
                ? publishedDateRaw.toDate() 
                : (publishedDateRaw is String ? DateTime.tryParse(publishedDateRaw) : null);
            
            return ConversationSourceModel(
              thumbnail: sourceData['thumbnail'] ?? '',
              favicon: sourceData['favicon'],
              url: sourceData['url'] ?? '',
              title: sourceData['title'] ?? '',
              description: sourceData['description'] ?? '',
              domain: sourceData['domain'] ?? '',
              publishedDate: publishedDate,
              source: sourceData['source'],
            );
          }).toList() ?? [],
          relatedQuestions: List<String>.from(messageData['relatedQuestions'] ?? []),
          images: List<String>.from(messageData['images'] ?? []),
          videos: (messageData['videos'] as List<dynamic>?)?.map((videoData) {
            final publishedDate = videoData['publishedDate'];
            return ConversationVideoModel(
              thumbnail: videoData['thumbnail'],
              url: videoData['url'] ?? '',
              title: videoData['title'] ?? '',
              description: videoData['description'],
              domain: videoData['domain'],
              duration: videoData['duration'],
              publishedDate: publishedDate is Timestamp ? publishedDate.toDate() : 
                            publishedDate is String ? DateTime.tryParse(publishedDate) : null,
              views: videoData['views'],
            );
          }).toList() ?? [],
          attachments: (messageData['attachments'] as List<dynamic>?)?.map((attachmentData) {
            final uploadedAt = (attachmentData['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return ConversationAttachmentModel.create(
              attachmentId: attachmentData['attachmentId'] ?? '',
              name: attachmentData['name'] ?? '',
              path: attachmentData['path'] ?? '',
              type: attachmentData['type'] ?? '',
              size: attachmentData['size'] ?? 0,
              uploadedAt: uploadedAt,
              extractedText: attachmentData['extractedText'],
            );
          }).toList() ?? [],
          isFallback: messageData['isFallback'] ?? false,
          errorMessage: messageData['errorMessage'],
          branchId: messageData['branchId'],
          parentBranchId: messageData['parentBranchId'],
          branchIndex: messageData['branchIndex'] ?? 0,
          totalBranches: messageData['totalBranches'] ?? 1,
        );
      }).toList() ?? [],
    );
  }
}