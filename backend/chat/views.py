from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import models
from .models import ChatRoom, Message
from .serializers import ChatRoomSerializer, MessageSerializer
from rides.models import Booking
from rest_framework.exceptions import PermissionDenied

class GetOrCreateChatRoomView(APIView):
    """Get or create a chat room for a booking"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        booking_id = request.data.get('booking_id')
        
        if not booking_id:
            return Response(
                {"error": "booking_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            booking = Booking.objects.select_related('ride__driver', 'passenger').get(id=booking_id)
            
            # Check if user is part of this booking
            if request.user != booking.passenger and request.user != booking.ride.driver:
                return Response(
                    {"error": "You are not authorized to access this chat"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get or create chat room
            chat_room, created = ChatRoom.objects.get_or_create(
                booking=booking,
                defaults={
                    'driver': booking.ride.driver,
                    'passenger': booking.passenger
                }
            )
            
            serializer = ChatRoomSerializer(chat_room, context={'request': request})
            
            return Response({
                'chat_room': serializer.data,
                'created': created
            })
            
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class MyChatRoomsView(generics.ListAPIView):
    """Get all chat rooms for current user"""
    serializer_class = ChatRoomSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return ChatRoom.objects.filter(
            models.Q(driver=user) | models.Q(passenger=user)
        ).select_related('driver', 'passenger', 'booking', 'booking__ride')

    def get_serializer_context(self):
        return {'request': self.request}


class ChatMessagesView(generics.ListCreateAPIView):
    """Get messages for a chat room and send new messages"""
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        chat_room_id = self.kwargs.get('chat_room_id')

        try:
            chat_room = ChatRoom.objects.get(id=chat_room_id)

            if self.request.user != chat_room.driver and self.request.user != chat_room.passenger:
                raise PermissionDenied("You are not part of this chat room")

        except ChatRoom.DoesNotExist:
            return Message.objects.none()

        return Message.objects.filter(
            chat_room_id=chat_room_id
        ).select_related('sender').order_by('created_at')

    def perform_create(self, serializer):
        chat_room_id = self.kwargs.get('chat_room_id')
        
        try:
            chat_room = ChatRoom.objects.get(id=chat_room_id)
            
            # Verify user has access
            if self.request.user != chat_room.driver and self.request.user != chat_room.passenger:
                raise PermissionError("You don't have access to this chat")
            
            serializer.save(
                chat_room=chat_room,
                sender=self.request.user
            )
            
        except ChatRoom.DoesNotExist:
            raise ValueError("Chat room not found")


class MarkMessagesAsReadView(APIView):
    """Mark all messages in a chat room as read"""
    permission_classes = [IsAuthenticated]

    def post(self, request, chat_room_id):
        try:
            chat_room = ChatRoom.objects.get(id=chat_room_id)
            
            # Verify user has access
            if request.user != chat_room.driver and request.user != chat_room.passenger:
                return Response(
                    {"error": "Access denied"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Mark all messages NOT sent by current user as read
            Message.objects.filter(
                chat_room=chat_room,
                is_read=False
            ).exclude(sender=request.user).update(is_read=True)
            
            return Response({"message": "Messages marked as read"})
            
        except ChatRoom.DoesNotExist:
            return Response(
                {"error": "Chat room not found"},
                status=status.HTTP_404_NOT_FOUND
            )