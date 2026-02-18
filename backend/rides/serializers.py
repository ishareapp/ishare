from rest_framework import serializers
from .models import Ride, Booking, Rating

class RideSerializer(serializers.ModelSerializer):
    car_photo_url = serializers.SerializerMethodField()
    driver_name = serializers.SerializerMethodField()
    driver_phone = serializers.SerializerMethodField()
    car_model = serializers.SerializerMethodField()
    
    class Meta:
        model = Ride
        fields = '__all__'
        read_only_fields = ['driver', 'status', 'car_photo']
    
    def get_car_photo_url(self, obj):
        """Get full URL for car photo"""
        if obj.car_photo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.car_photo.url)
            return obj.car_photo.url
        return None
    
    def get_driver_name(self, obj):
        """Get driver's name"""
        return obj.driver.username
    
    def get_driver_phone(self, obj):
        """Get driver's phone"""
        return obj.driver.phone
    
    def get_car_model(self, obj):
        """Get car model from driver profile"""
        try:
            return obj.driver.driverprofile.car_model
        except:
            return None


class BookingSerializer(serializers.ModelSerializer):
    ride = RideSerializer(read_only=True)  # Full ride object, not just ID
    passenger_name = serializers.CharField(source='passenger.username', read_only=True)
    passenger_phone = serializers.CharField(source='passenger.phone', read_only=True)
    driver_name = serializers.SerializerMethodField()  # ✅ ADDED: For chat on passenger side
    
    class Meta:
        model = Booking
        fields = '__all__'
    
    def get_driver_name(self, obj):
        """Get driver's name for chat"""
        return obj.ride.driver.username
    
    def to_representation(self, instance):
        """Ensure all numeric fields are integers, not strings"""
        data = super().to_representation(instance)
        
        # Convert string numbers to integers
        if 'seats_booked' in data and data['seats_booked']:
            data['seats_booked'] = int(data['seats_booked'])
        
        if 'total_price' in data and data['total_price']:
            # Keep as string for display, but ensure it's valid
            data['total_price'] = str(data['total_price'])
        
        return data


class RatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Rating
        fields = "__all__"
        read_only_fields = ("reviewer",)