# Create new file: backend/chat/models.py

from django.db import models
from django.conf import settings
from rides.models import Booking

class ChatRoom(models.Model):
    """Chat room between driver and passenger for a specific booking"""
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='chat_room')
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='driver_chats'
    )
    passenger = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='passenger_chats'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['driver', 'passenger', 'booking']
        ordering = ['-updated_at']

    def __str__(self):
        return f"Chat: {self.passenger.username} - {self.driver.username} (Booking #{self.booking.id})"


class Message(models.Model):
    """Individual messages in a chat room"""
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender.username}: {self.content[:50]}"


# Then create migrations:
# python manage.py makemigrations chat
# python manage.py migrate chat