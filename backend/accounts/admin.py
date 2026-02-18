from django.contrib import admin
from .models import User, Notification


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = (
        "email",
        "role",
        "phone",
        "is_staff",
        "is_active",
        "average_rating_display",
    )
    list_filter = ("role", "is_staff", "is_active")
    search_fields = ("email", "phone")

    def average_rating_display(self, obj):
        return obj.average_rating()
    average_rating_display.short_description = "Avg Rating"


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("user", "title", "is_read", "created_at")
    list_filter = ("is_read",)
    search_fields = ("user__email", "title")
