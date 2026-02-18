import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/storage_service.dart';
import 'chat_screen.dart';
import '../../core/extensions/translation_extension.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    setState(() => isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      
      final response = await http.get(
        Uri.parse("${StorageService.baseUrl}/chat/my-chats/"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          chats = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
              ? const Center(child: Text("No conversations yet"))
              : RefreshIndicator(
                  onRefresh: fetchChats,
                  child: ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUser = _getOtherUser(chat);
                      final lastMessage = chat['last_message'];
                      final unreadCount = chat['unread_count'] ?? 0;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(otherUser[0].toUpperCase()),
                        ),
                        title: Text(
                          otherUser,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage != null 
                              ? lastMessage['content'] 
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: unreadCount > 0
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatRoomId: chat['id'],
                                otherUserName: otherUser,
                              ),
                            ),
                          ).then((_) => fetchChats());
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _getOtherUser(Map chat) {
    final role = StorageService.getRole();
    return role == 'driver' 
        ? chat['passenger_name'] 
        : chat['driver_name'];
  }
}