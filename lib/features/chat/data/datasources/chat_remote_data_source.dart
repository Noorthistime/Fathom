import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatModel>> streamChats(String userId) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatModel.fromMap(doc.data(), doc.id);
      }).toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    });
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<ChatModel> createChat({
    required String userId,
    String? projectId,
    required String title,
  }) async {
    final docRef = _firestore.collection('chats').doc();
    final chat = ChatModel(
      id: docRef.id,
      userId: userId,
      projectId: projectId,
      title: title,
      isPinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(chat.toMap());
    return chat;
  }

  Future<void> addMessage({
    required String chatId,
    required String role,
    required String content,
  }) async {
    final batch = _firestore.batch();
    
    final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    final msg = MessageModel(
      id: msgRef.id,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
    
    batch.set(msgRef, msg.toMap());
    
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    await batch.commit();
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    await _firestore.collection('chats').doc(chatId).update({
      'title': newTitle,
    });
  }

  Future<void> deleteChat(String chatId) async {
    // Delete all messages subcollection first, then delete the chat doc.
    final messagesSnapshot = await _firestore.collection('chats').doc(chatId).collection('messages').get();
    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }

  Future<void> togglePinChat(String chatId, bool currentPinnedState) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isPinned': !currentPinnedState,
    });
  }

  Future<void> moveChatToProject(String chatId, String? projectId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'projectId': projectId,
    });
  }

  Future<void> migrateGuestChats(String guestUid, String registeredUid) async {
    final chatsSnapshot = await _firestore.collection('chats').where('userId', isEqualTo: guestUid).get();
    for (var chatDoc in chatsSnapshot.docs) {
      final oldChatId = chatDoc.id;
      final data = chatDoc.data();
      data['userId'] = registeredUid;
      
      // Copy chat
      final newChatRef = _firestore.collection('chats').doc(oldChatId);
      await newChatRef.set(data);
      
      // Copy messages
      final messagesSnapshot = await _firestore.collection('chats').doc(oldChatId).collection('messages').get();
      for (var msgDoc in messagesSnapshot.docs) {
        await newChatRef.collection('messages').doc(msgDoc.id).set(msgDoc.data());
      }
    }
  }
}
