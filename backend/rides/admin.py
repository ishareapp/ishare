from django.contrib import admin
from .models import Ride, Booking, Rating


@admin.register(Ride)
class RideAdmin(admin.ModelAdmin):
    list_display = (
        "driver",
        "start_location",
        "destination",
        "departure_time",
        "available_seats",
        "status",
    )
    list_filter = ("status", "departure_time")
    search_fields = ("start_location", "destination", "driver__email")


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = (
        "passenger",
        "ride",
        "status",
        "total_price",
        "created_at",
    )
    list_filter = ("status",)
    search_fields = ("passenger__email",)


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ("reviewer", "reviewee", "score", "created_at")
    list_filter = ("score",)
    search_fields = ("reviewer__email", "reviewee__email")
