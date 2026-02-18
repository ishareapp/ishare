from rest_framework import serializers
from .models import ChatRoom, Message

class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.username', read_only=True)
    sender_role = serializers.CharField(source='sender.role', read_only=True)

    class Meta:
        model = Message
        fields = [
            'id',
            'chat_room',
            'sender',
            'sender_name',
            'sender_role',
            'content',
            'is_read',
            'created_at'
        ]
        read_only_fields = ['sender', 'chat_room', 'created_at']



class ChatRoomSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.username', read_only=True)
    passenger_name = serializers.CharField(source='passenger.username', read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    booking_details = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = ['id', 'booking', 'driver', 'driver_name', 'passenger', 'passenger_name', 
                  'last_message', 'unread_count', 'booking_details', 'created_at', 'updated_at']
        read_only_fields = ['driver', 'passenger', 'created_at', 'updated_at']
    
    def get_last_message(self, obj):
        last_msg = obj.messages.last()
        if last_msg:
            return {
                'content': last_msg.content,
                'sender': last_msg.sender.username,
                'created_at': last_msg.created_at
            }
        return None
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0
    
    def get_booking_details(self, obj):
        booking = obj.booking
        return {
            'id': booking.id,
            'route': f"{booking.ride.start_location} → {booking.ride.destination}",
            'status': booking.status,
        }