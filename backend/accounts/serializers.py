from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import PassengerProfile, DriverProfile
from datetime import date, timedelta
from .models import Subscription
from .models import Notification  # <-- ADD THIS LINE


User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['email', 'username', 'phone', 'password', 'role']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()

        # Auto create profile
        if user.role == 'passenger':
            PassengerProfile.objects.create(user=user)
        elif user.role == 'driver':
            DriverProfile.objects.create(
                user=user,
                national_id="TEMP",
                driver_license="TEMP",
                car_model="TEMP",
                plate_number="TEMP",
                seats_available=4
            )

        return user
def create(self, validated_data):
    password = validated_data.pop('password')
    user = User(**validated_data)
    user.set_password(password)
    user.save()

    # Auto create profile
    if user.role == 'passenger':
        PassengerProfile.objects.create(user=user)
    elif user.role == 'driver':
        DriverProfile.objects.create(
            user=user,
            national_id="TEMP",
            driver_license="TEMP",
            car_model="TEMP",
            plate_number="TEMP",
            seats_available=4
        )

    # Create free trial subscription (1 month)
    Subscription.objects.create(
        user=user,
        plan_type=user.role,
        expiry_date=date.today() + timedelta(days=30),
        is_trial=True
    )

    return user
class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = "__all__"
