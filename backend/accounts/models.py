from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings

class User(AbstractUser):
    ROLE_CHOICES = (
        ('passenger', 'Passenger'),
        ('driver', 'Driver'),
    )

    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_warned = models.BooleanField(default=False)
    is_restricted = models.BooleanField(default=False)
    
    # ADD THESE NEW FIELDS:
    email_verified = models.BooleanField(default=False)
    email_verification_token = models.CharField(max_length=100, blank=True, null=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True)  # For push notifications

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'phone', 'role']

    def __str__(self):
        return self.email

class PassengerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    profile_photo = models.ImageField(upload_to='passengers/', blank=True, null=True)
    rating = models.FloatField(default=5.0)
    subscription_active = models.BooleanField(default=False)
    subscription_expiry = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"Passenger: {self.user.email}"


class DriverProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    profile_photo = models.ImageField(upload_to='drivers/', blank=True, null=True)
    national_id = models.CharField(max_length=20)
    driver_license = models.CharField(max_length=50)
    car_model = models.CharField(max_length=100)
    plate_number = models.CharField(max_length=20)
    seats_available = models.IntegerField()
    rating = models.FloatField(default=5.0)
    is_verified_by_admin = models.BooleanField(default=False)
    subscription_active = models.BooleanField(default=False)
    subscription_expiry = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"Driver: {self.user.email}"
     # ADD THESE NEW FIELDS:
    national_id_photo = models.ImageField(upload_to='driver_documents/national_ids/', blank=True, null=True)
    driver_license_photo = models.ImageField(upload_to='driver_documents/licenses/', blank=True, null=True)
    car_registration = models.ImageField(upload_to='driver_documents/registrations/', blank=True, null=True)
    car_photo_front = models.ImageField(upload_to='driver_documents/car_photos/', blank=True, null=True)
    car_photo_side = models.ImageField(upload_to='driver_documents/car_photos/', blank=True, null=True)
    
    # Document verification status
    VERIFICATION_STATUS = (
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )
    verification_status = models.CharField(
        max_length=20, 
        choices=VERIFICATION_STATUS, 
        default='pending'
    )
    verification_notes = models.TextField(blank=True, null=True)
    documents_uploaded_at = models.DateTimeField(blank=True, null=True)    

class Subscription(models.Model):
    PLAN_CHOICES = (
        ('passenger', 'Passenger Plan'),
        ('driver', 'Driver Plan'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    plan_type = models.CharField(max_length=20, choices=PLAN_CHOICES)
    start_date = models.DateField(auto_now_add=True)
    expiry_date = models.DateField()
    is_active = models.BooleanField(default=True)
    auto_renew = models.BooleanField(default=True)
    is_trial = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.user.email} - {self.plan_type}"
def average_rating(self):
    ratings = self.received_ratings.all()
    if ratings.exists():
        return round(
            sum(r.score for r in ratings) / ratings.count(), 2
        )
    return 0
User.add_to_class("average_rating", average_rating)
is_warned = models.BooleanField(default=False)
is_restricted = models.BooleanField(default=False)
def evaluate_trust_status(self):
    avg = self.average_rating()

    if avg < 2.0 and self.received_ratings.exists():
        self.is_restricted = True
        self.is_warned = True

    elif avg < 3.0 and self.received_ratings.exists():
        self.is_warned = True
        self.is_restricted = False

    else:
        self.is_warned = False
        self.is_restricted = False

    self.save()


class Notification(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications"
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.title}"
