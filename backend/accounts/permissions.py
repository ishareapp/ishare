from rest_framework.permissions import BasePermission
from datetime import date
from .models import Subscription


class HasActiveSubscription(BasePermission):
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False

        try:
            subscription = Subscription.objects.get(user=request.user)

            if subscription.expiry_date >= date.today() and subscription.is_active:
                return True

            return False
        except Subscription.DoesNotExist:
            return False
