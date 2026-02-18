import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/services/storage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/extensions/translation_extension.dart';

class ChatScreen extends StatefulWidget {
  final int chatRoomId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> messages = [];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool isLoading = true;
  bool isSending = false;
  String? userRole;
  Timer? _pollingTimer;
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    print("🔥 OPENED CHAT ROOM: ${widget.chatRoomId}");
    
    _loadUserRole();
    fetchMessages();
    markAsRead();
    _initWebSocket();
    
    // Start polling every 2 seconds as fallback
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchMessages();
    });
  }

  void _initWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse("ws://127.0.0.1:8000/ws/chat/${widget.chatRoomId}/"),
      );

      channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            setState(() {
              messages.add(message);
            });
            _scrollToBottom();
          } catch (e) {
            print("❌ WebSocket message parse error: $e");
          }
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
        },
        onDone: () {
          print("⚠️ WebSocket connection closed");
        },
      );
    } catch (e) {
      print("❌ WebSocket connection failed: $e");
    }
  }

  Future<void> _loadUserRole() async {
    userRole = await StorageService.getRole();
    setState(() {});
  }

  Future<void> fetchMessages() async {
    try {
      final token = await StorageService.getToken();
      final url = "${StorageService.baseUrl}/chat/${widget.chatRoomId}/messages/";
      
      print("📡 Fetching messages from: $url");
      print("📌 Chat Room ID: ${widget.chatRoomId}");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      print("✅ Status Code: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final newMessages = jsonDecode(response.body);
        print("🧾 Parsed Messages Count: ${newMessages.length}");

        setState(() {
          messages = newMessages;
          isLoading = false;
        });

        _scrollToBottom();
      } else {
        print("❌ Failed to fetch messages");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("🔥 Fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> markAsRead() async {
    try {
      final token = await StorageService.getToken();
      await http.post(
        Uri.parse("${StorageService.baseUrl}/chat/${widget.chatRoomId}/mark-read/"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (e) {
      print("⚠️ Mark as read error: $e");
    }
  }

  Future<void> sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => isSending = true);

    try {
      final token = await StorageService.getToken();
      
      final response = await http.post(
        Uri.parse("${StorageService.baseUrl}/chat/${widget.chatRoomId}/messages/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"content": content}),
      );

      print("📤 Send Status: ${response.statusCode}");
      print("📤 Send Response: ${response.body}");

      if (response.statusCode == 201) {
        _messageController.clear();
        
        // Send via WebSocket if connected
        if (channel != null) {
          try {
            channel!.sink.add(jsonEncode({
              "message": content,
            }));
          } catch (e) {
            print("⚠️ WebSocket send error: $e");
          }
        }
        
        // Fetch immediately after sending as fallback
        fetchMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send message: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      print("❌ Send error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message['sender_role'] == userRole;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isSending ? null : sendMessage,
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}