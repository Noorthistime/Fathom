import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/gemini_remote_data_source.dart';
import 'dart:async';

class ChatProvider extends ChangeNotifier {
  final ChatRemoteDataSource _chatDataSource = ChatRemoteDataSource();
  final GeminiRemoteDataSource _geminiDataSource = GeminiRemoteDataSource();

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _selectedChatId;

  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String? get selectedChatId => _selectedChatId;

  ChatModel? get selectedChat {
    if (_selectedChatId == null) return null;
    return _chats.firstWhere((c) => c.id == _selectedChatId);
  }

  void initializeChats(String userId) {
    _isLoading = true;
    notifyListeners();
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatDataSource.streamChats(userId).listen(
      (data) {
        _chats = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void selectChat(String? chatId) {
    _selectedChatId = chatId;
    _messages = [];
    _messagesSubscription?.cancel();
    notifyListeners();

    if (chatId != null) {
      _isLoading = true;
      notifyListeners();
      _messagesSubscription = _chatDataSource.streamMessages(chatId).listen(
        (data) {
          _messages = data;
          _isLoading = false;
          notifyListeners();
        },
        onError: (err) {
          _errorMessage = err.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> createNewChat(String userId, String firstPrompt, String apiKey) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Generate Title
      final title = await _geminiDataSource.generateChatTitle(
        apiKey: apiKey,
        firstPrompt: firstPrompt,
      );

      // 2. Save Chat doc to firestore
      final chat = await _chatDataSource.createChat(
        userId: userId,
        title: title,
      );

      _selectedChatId = chat.id;

      // 3. Save User message to firestore subcollection
      await _chatDataSource.addMessage(
        chatId: chat.id,
        role: 'user',
        content: firstPrompt,
      );

      // 4. Generate & Save model response
      final modelResponse = await _geminiDataSource.generateResponse(
        apiKey: apiKey,
        history: [],
        prompt: firstPrompt,
      );

      await _chatDataSource.addMessage(
        chatId: chat.id,
        role: 'model',
        content: modelResponse,
      );

      _isGenerating = false;
      selectChat(chat.id);
    } catch (e) {
      _errorMessage = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String prompt, String apiKey) async {
    if (_selectedChatId == null) return;
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Add User message
      await _chatDataSource.addMessage(
        chatId: _selectedChatId!,
        role: 'user',
        content: prompt,
      );

      // 2. Generate Gemini response
      // Pass copy of current history *excluding* the newly written message which might still be syncing
      final modelResponse = await _geminiDataSource.generateResponse(
        apiKey: apiKey,
        history: _messages,
        prompt: prompt,
      );

      // 3. Add Model message
      await _chatDataSource.addMessage(
        chatId: _selectedChatId!,
        role: 'model',
        content: modelResponse,
      );

      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> regenerateResponse(String apiKey) async {
    if (_selectedChatId == null || _messages.isEmpty) return;
    
    // Find the last user prompt
    String? lastUserPrompt;
    List<MessageModel> contextHistory = [];
    
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        lastUserPrompt = _messages[i].content;
        contextHistory = _messages.sublist(0, i);
        break;
      }
    }

    if (lastUserPrompt == null) return;

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete the last model message if it exists
      if (_messages.last.role == 'model') {
        final lastMsg = _messages.last;
        // In this implementation, we just call the API to generate a new one,
        // and overwrite or append. We append as a new response.
      }

      final modelResponse = await _geminiDataSource.generateResponse(
        apiKey: apiKey,
        history: contextHistory,
        prompt: lastUserPrompt,
      );

      await _chatDataSource.addMessage(
        chatId: _selectedChatId!,
        role: 'model',
        content: modelResponse,
      );

      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    try {
      await _chatDataSource.renameChat(chatId, newTitle);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      if (_selectedChatId == chatId) {
        _selectedChatId = null;
        _messages = [];
        _messagesSubscription?.cancel();
      }
      await _chatDataSource.deleteChat(chatId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> togglePinChat(ChatModel chat) async {
    try {
      await _chatDataSource.togglePinChat(chat.id, chat.isPinned);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> moveChatToProject(String chatId, String? projectId) async {
    try {
      await _chatDataSource.moveChatToProject(chatId, projectId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> migrateGuestChats(String guestUid, String registeredUid) async {
    try {
      await _chatDataSource.migrateGuestChats(guestUid, registeredUid);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
