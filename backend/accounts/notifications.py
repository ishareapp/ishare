from firebase_admin import messaging
from .models import Notification

def send_push_notification(user, title, body, data=None):
    """
    Send push notification to user
    
    Args:
        user: User object
        title: Notification title
        body: Notification message
        data: Additional data (optional dict)
    """
    
    # Always save to database
    Notification.objects.create(
        user=user,
        title=title,
        message=body
    )
    print(f"📧 Notification saved to DB for {user.email}: {title}")
    
    # Try to send push notification if user has FCM token
    fcm_token = getattr(user, 'fcm_token', None)
    
    if not fcm_token:
        print(f"⚠️  No FCM token for user {user.email} - notification saved to DB only")
        return
    
    try:
        # Create Firebase message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=fcm_token,
        )
        
        # Send notification
        response = messaging.send(message)
        print(f"✅ Push notification sent successfully: {response}")
        
    except Exception as e:
        print(f"❌ Error sending push notification: {e}")