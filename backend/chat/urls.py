from django.urls import path
from .views import (
    GetOrCreateChatRoomView,
    MyChatRoomsView,
    ChatMessagesView,
    MarkMessagesAsReadView,
)

urlpatterns = [
    path('create/', GetOrCreateChatRoomView.as_view(), name='create_chat_room'),
    path('my-chats/', MyChatRoomsView.as_view(), name='my_chat_rooms'),
    path('<int:chat_room_id>/messages/', ChatMessagesView.as_view(), name='chat_messages'),
    path('<int:chat_room_id>/mark-read/', MarkMessagesAsReadView.as_view(), name='mark_messages_read'),
]
