from rest_framework import generics
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, NotificationSerializer
from .models import Notification
from django.db.models import Sum
from rest_framework.permissions import IsAdminUser
from accounts.models import User
from .models import Subscription
from datetime import date, timedelta
from rest_framework import status
from django.conf import settings
from django.utils import timezone
import random
from .models import User
import secrets
from rest_framework.parsers import MultiPartParser, FormParser
from datetime import datetime
from .models import DriverProfile
from rides.models import Ride, Booking, Rating
from django.db.models import Sum, Count, Q, Avg
from django.db.models.functions import TruncDate, TruncMonth
from datetime import datetime, timedelta
from decimal import Decimal
from rest_framework.decorators import api_view, permission_classes
from .email_service import send_verification_email, send_welcome_email

User = get_user_model()
import logging
logger = logging.getLogger(__name__)


class ProcessPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        phone_number = request.data.get("phone_number")
        payment_method = request.data.get("payment_method")
        amount = request.data.get("amount", 5000)

        if not phone_number or not payment_method:
            return Response(
                {"error": "Phone number and payment method are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if amount != 5000:
            return Response(
                {"error": "Invalid amount. Subscription costs 5000 RWF"},
                status=status.HTTP_400_BAD_REQUEST
            )

        payment_successful = self._process_mobile_money_payment(
            phone_number, payment_method, amount
        )

        if not payment_successful:
            return Response(
                {"error": "Payment processing failed. Please try again."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            subscription = Subscription.objects.get(user=request.user)
            if subscription.expiry_date < date.today():
                subscription.expiry_date = date.today() + timedelta(days=30)
            else:
                subscription.expiry_date += timedelta(days=30)
            subscription.is_active = True
            subscription.is_trial = False
            subscription.save()

        except Subscription.DoesNotExist:
            role = request.user.role
            subscription = Subscription.objects.create(
                user=request.user,
                plan_type=role,
                expiry_date=date.today() + timedelta(days=30),
                is_active=True,
                is_trial=False,
            )

        return Response(
            {
                "message": "Payment successful! Subscription activated.",
                "subscription": {
                    "plan_type": subscription.plan_type,
                    "expiry_date": subscription.expiry_date,
                    "is_active": subscription.is_active,
                    "is_trial": subscription.is_trial,
                }
            },
            status=status.HTTP_200_OK
        )

    def _process_mobile_money_payment(self, phone_number, payment_method, amount):
        logger.info(f"Payment attempt: {payment_method} - {phone_number} - {amount} RWF")
        return True


class CheckSubscriptionStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            subscription = Subscription.objects.get(user=request.user)
            today = date.today()
            days_remaining = (subscription.expiry_date - today).days
            is_expired = subscription.expiry_date < today
            return Response({
                "has_subscription": True,
                "is_active": subscription.is_active and not is_expired,
                "is_trial": subscription.is_trial,
                "expiry_date": subscription.expiry_date,
                "days_remaining": max(0, days_remaining),
                "is_expired": is_expired,
            })
        except Subscription.DoesNotExist:
            return Response({
                "has_subscription": False,
                "is_active": False,
            })


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        Subscription.objects.create(
            user=user,
            plan_type=user.role,
            expiry_date=date.today() + timedelta(days=30),
            is_active=True,
            is_trial=True,
        )

        send_welcome_email(user.email, user.username, user.role)

        refresh = RefreshToken.for_user(user)

        return Response({
            "user": serializer.data,
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        })


class UserNotificationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(user=request.user).order_by("-created_at")
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data)


class AdminDashboardView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        total_users = User.objects.count()
        total_drivers = User.objects.filter(role="driver").count()
        total_passengers = User.objects.filter(role="passenger").count()
        total_rides = Ride.objects.count()
        active_rides = Ride.objects.filter(status="active").count()
        completed_rides = Ride.objects.filter(status="completed").count()
        total_bookings = Booking.objects.count()
        total_revenue = Booking.objects.filter(
            status="completed"
        ).aggregate(total=Sum("total_price"))["total"] or 0

        blocked_users = [
            user.id for user in User.objects.all()
            if user.average_rating() < 2.5 and user.received_ratings.exists()
        ]

        return Response({
            "users": {
                "total": total_users,
                "drivers": total_drivers,
                "passengers": total_passengers,
                "blocked_users_count": len(blocked_users)
            },
            "rides": {
                "total": total_rides,
                "active": active_rides,
                "completed": completed_rides,
            },
            "bookings": {
                "total": total_bookings,
            },
            "revenue": {
                "total_completed_revenue": total_revenue
            }
        })


class SubscriptionView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            subscription = Subscription.objects.get(user=request.user)
            data = {
                "plan_type": subscription.plan_type,
                "start_date": subscription.start_date,
                "expiry_date": subscription.expiry_date,
                "is_active": subscription.is_active,
                "auto_renew": subscription.auto_renew,
                "is_trial": subscription.is_trial,
            }
            return Response(data, status=status.HTTP_200_OK)
        except Subscription.DoesNotExist:
            return Response(
                {"error": "No subscription found"},
                status=status.HTTP_404_NOT_FOUND
            )


class CreateSubscriptionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        plan_type = request.data.get("plan_type")
        is_trial = request.data.get("is_trial", True)

        if plan_type not in ['passenger', 'driver']:
            return Response(
                {"error": "Invalid plan type"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if Subscription.objects.filter(user=request.user).exists():
            return Response(
                {"error": "Subscription already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        expiry_date = date.today() + timedelta(days=30)
        subscription = Subscription.objects.create(
            user=request.user,
            plan_type=plan_type,
            expiry_date=expiry_date,
            is_active=True,
            is_trial=is_trial,
        )

        return Response(
            {
                "message": "Subscription activated successfully",
                "plan_type": subscription.plan_type,
                "expiry_date": subscription.expiry_date,
                "is_trial": subscription.is_trial,
            },
            status=status.HTTP_201_CREATED
        )


class CurrentUserView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        return Response({
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "role": user.role,
            "phone": user.phone,
            "email_verified": user.email_verified,
            "is_superuser": user.is_superuser,
            "is_staff": user.is_staff,
        })


class SendEmailVerificationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.email_verified:
            return Response(
                {"message": "Email already verified"},
                status=status.HTTP_400_BAD_REQUEST
            )
        token = secrets.token_urlsafe(32)
        user.email_verification_token = token
        user.save()
        verification_link = f"{settings.SITE_URL}/api/accounts/verify-email/{token}"
        success = send_verification_email(user.email, user.username, verification_link)
        if success:
            return Response(
                {"message": "Verification email sent successfully"},
                status=status.HTTP_200_OK
            )
        return Response(
            {"error": "Failed to send email"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, token):
        try:
            user = User.objects.get(email_verification_token=token)
            if user.email_verified:
                return Response(
                    {"message": "Email already verified"},
                    status=status.HTTP_200_OK
                )
            user.email_verified = True
            user.email_verification_token = None
            user.save()
            return Response(
                {"message": "Email verified successfully! You can now close this page."},
                status=status.HTTP_200_OK
            )
        except User.DoesNotExist:
            return Response(
                {"error": "Invalid or expired verification token"},
                status=status.HTTP_400_BAD_REQUEST
            )


class UploadDriverDocumentsView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        user = request.user
        if user.role != 'driver':
            return Response(
                {"error": "Only drivers can upload documents"},
                status=status.HTTP_403_FORBIDDEN
            )
        try:
            driver_profile = DriverProfile.objects.get(user=user)
        except DriverProfile.DoesNotExist:
            driver_profile = DriverProfile.objects.create(
                user=user,
                national_id='',
                driver_license='',
                car_model='',
                plate_number='',
                seats_available=4,
            )

        is_admin = user.is_staff or user.is_superuser

        if 'national_id_photo' in request.FILES:
            driver_profile.national_id_photo = request.FILES['national_id_photo']
        if 'driver_license_photo' in request.FILES:
            driver_profile.driver_license_photo = request.FILES['driver_license_photo']
        if 'car_registration' in request.FILES:
            driver_profile.car_registration = request.FILES['car_registration']
        if 'car_photo_front' in request.FILES:
            driver_profile.car_photo_front = request.FILES['car_photo_front']
        if 'car_photo_side' in request.FILES:
            driver_profile.car_photo_side = request.FILES['car_photo_side']

        if is_admin:
            driver_profile.verification_status = 'approved'
            driver_profile.is_verified_by_admin = True
            driver_profile.documents_uploaded_at = datetime.now()
            driver_profile.save()
            return Response(
                {
                    "message": "Admin documents uploaded and auto-approved!",
                    "verification_status": driver_profile.verification_status,
                    "is_admin": True
                },
                status=status.HTTP_200_OK
            )

        driver_profile.verification_status = 'pending'
        driver_profile.documents_uploaded_at = datetime.now()
        driver_profile.save()
        return Response(
            {
                "message": "Documents uploaded successfully. Waiting for admin approval.",
                "verification_status": driver_profile.verification_status,
                "is_admin": False
            },
            status=status.HTTP_200_OK
        )


class GetDriverDocumentsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role != 'driver':
            return Response(
                {"error": "Only drivers can access this"},
                status=status.HTTP_403_FORBIDDEN
            )
        if user.is_staff or user.is_superuser:
            return Response({
                "verification_status": "approved",
                "is_verified": True,
                "is_admin": True,
                "documents_uploaded": {
                    "national_id": True,
                    "driver_license": True,
                    "car_registration": True,
                    "car_photo_front": True,
                    "car_photo_side": True,
                },
                "verification_notes": "Admin account - automatically verified",
                "documents_uploaded_at": None,
            })
        try:
            driver_profile = DriverProfile.objects.get(user=user)
            return Response({
                "verification_status": driver_profile.verification_status,
                "is_verified": driver_profile.is_verified_by_admin,
                "is_admin": False,
                "documents_uploaded": {
                    "national_id": bool(driver_profile.national_id_photo),
                    "driver_license": bool(driver_profile.driver_license_photo),
                    "car_registration": bool(driver_profile.car_registration),
                    "car_photo_front": bool(driver_profile.car_photo_front),
                    "car_photo_side": bool(driver_profile.car_photo_side),
                },
                "verification_notes": driver_profile.verification_notes,
                "documents_uploaded_at": driver_profile.documents_uploaded_at,
            })
        except DriverProfile.DoesNotExist:
            return Response(
                {"error": "Driver profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class AdminVerifyDriverView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, driver_id):
        action = request.data.get('action')
        notes = request.data.get('notes', '')

        if action not in ['approve', 'reject']:
            return Response(
                {"error": "Action must be 'approve' or 'reject'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            driver_profile = DriverProfile.objects.get(id=driver_id)
            if action == 'approve':
                driver_profile.verification_status = 'approved'
                driver_profile.is_verified_by_admin = True
            else:
                driver_profile.verification_status = 'rejected'
                driver_profile.is_verified_by_admin = False
            driver_profile.verification_notes = notes
            driver_profile.save()

            from accounts.notifications import send_push_notification
            if action == 'approve':
                send_push_notification(
                    user=driver_profile.user,
                    title="Documents Approved! ✅",
                    body="Your driver documents have been approved. You can now create rides!",
                    data={"type": "verification_approved"}
                )
            else:
                send_push_notification(
                    user=driver_profile.user,
                    title="Documents Rejected",
                    body=f"Your documents were rejected. Reason: {notes}",
                    data={"type": "verification_rejected"}
                )

            return Response({
                "message": f"Driver {action}d successfully",
                "verification_status": driver_profile.verification_status
            })
        except DriverProfile.DoesNotExist:
            return Response(
                {"error": "Driver not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class AdminGetPendingDriversView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        pending_drivers = DriverProfile.objects.filter(
            verification_status='pending'
        ).select_related('user')
        drivers_data = []
        for driver in pending_drivers:
            drivers_data.append({
                'id': driver.id,
                'user': {
                    'email': driver.user.email,
                    'username': driver.user.username,
                    'phone': driver.user.phone,
                },
                'national_id': driver.national_id,
                'driver_license': driver.driver_license,
                'car_model': driver.car_model,
                'plate_number': driver.plate_number,
                'documents': {
                    'national_id_photo': driver.national_id_photo.url if driver.national_id_photo else None,
                    'driver_license_photo': driver.driver_license_photo.url if driver.driver_license_photo else None,
                    'car_registration': driver.car_registration.url if driver.car_registration else None,
                    'car_photo_front': driver.car_photo_front.url if driver.car_photo_front else None,
                    'car_photo_side': driver.car_photo_side.url if driver.car_photo_side else None,
                },
                'documents_uploaded_at': driver.documents_uploaded_at,
            })
        return Response(drivers_data)


class AdminDashboardStatsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        today = date.today()
        last_30_days = today - timedelta(days=30)
        last_7_days = today - timedelta(days=7)

        total_users = User.objects.count()
        total_drivers = User.objects.filter(role="driver").count()
        total_passengers = User.objects.filter(role="passenger").count()
        new_users_30d = User.objects.filter(date_joined__gte=last_30_days).count()
        verified_drivers = DriverProfile.objects.filter(is_verified_by_admin=True).count()
        pending_verification = DriverProfile.objects.filter(verification_status='pending').count()

        total_rides = Ride.objects.count()
        active_rides = Ride.objects.filter(status="active").count()
        completed_rides = Ride.objects.filter(status="completed").count()
        rides_30d = Ride.objects.filter(created_at__gte=last_30_days).count()

        total_bookings = Booking.objects.count()
        confirmed_bookings = Booking.objects.filter(status='confirmed').count()
        pending_bookings = Booking.objects.filter(status='pending').count()
        bookings_30d = Booking.objects.filter(created_at__gte=last_30_days).count()

        total_revenue = Booking.objects.filter(
            status__in=['confirmed', 'completed']
        ).aggregate(total=Sum('total_price'))['total'] or Decimal('0.00')

        revenue_30d = Booking.objects.filter(
            status__in=['confirmed', 'completed'],
            created_at__gte=last_30_days
        ).aggregate(total=Sum('total_price'))['total'] or Decimal('0.00')

        revenue_7d = Booking.objects.filter(
            status__in=['confirmed', 'completed'],
            created_at__gte=last_7_days
        ).aggregate(total=Sum('total_price'))['total'] or Decimal('0.00')

        revenue_today = Booking.objects.filter(
            status__in=['confirmed', 'completed'],
            created_at__date=today
        ).aggregate(total=Sum('total_price'))['total'] or Decimal('0.00')

        subscription_revenue = Subscription.objects.filter(
            is_active=True, is_trial=False
        ).count() * 5000

        avg_booking_value = Booking.objects.filter(
            status__in=['confirmed', 'completed']
        ).aggregate(avg=Avg('total_price'))['avg'] or Decimal('0.00')

        active_subscriptions = Subscription.objects.filter(
            is_active=True, expiry_date__gte=today
        ).count()
        trial_subscriptions = Subscription.objects.filter(is_trial=True, is_active=True).count()
        paid_subscriptions = Subscription.objects.filter(is_trial=False, is_active=True).count()
        expired_subscriptions = Subscription.objects.filter(expiry_date__lt=today).count()

        total_ratings = Rating.objects.count()
        avg_driver_rating = Rating.objects.aggregate(avg=Avg('score'))['avg'] or 0.0

        prev_30_days = last_30_days - timedelta(days=30)
        prev_users = User.objects.filter(
            date_joined__gte=prev_30_days,
            date_joined__lt=last_30_days
        ).count()

        user_growth_rate = 0
        if prev_users > 0:
            user_growth_rate = ((new_users_30d - prev_users) / prev_users) * 100

        return Response({
            "users": {
                "total": total_users,
                "drivers": total_drivers,
                "passengers": total_passengers,
                "new_last_30_days": new_users_30d,
                "growth_rate": round(user_growth_rate, 2),
            },
            "drivers": {
                "total": total_drivers,
                "verified": verified_drivers,
                "pending_verification": pending_verification,
            },
            "rides": {
                "total": total_rides,
                "active": active_rides,
                "completed": completed_rides,
                "last_30_days": rides_30d,
            },
            "bookings": {
                "total": total_bookings,
                "confirmed": confirmed_bookings,
                "pending": pending_bookings,
                "last_30_days": bookings_30d,
            },
            "revenue": {
                "total": str(total_revenue),
                "last_30_days": str(revenue_30d),
                "last_7_days": str(revenue_7d),
                "today": str(revenue_today),
                "subscription_revenue": subscription_revenue,
                "average_booking_value": str(round(avg_booking_value, 2)),
            },
            "subscriptions": {
                "active": active_subscriptions,
                "trial": trial_subscriptions,
                "paid": paid_subscriptions,
                "expired": expired_subscriptions,
            },
            "ratings": {
                "total": total_ratings,
                "average": round(avg_driver_rating, 2),
            }
        })


class AdminRevenueChartView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        period = request.query_params.get('period', 'daily')
        if period == 'daily':
            thirty_days_ago = date.today() - timedelta(days=30)
            revenue_data = Booking.objects.filter(
                status__in=['confirmed', 'completed'],
                created_at__date__gte=thirty_days_ago
            ).annotate(date=TruncDate('created_at')).values('date').annotate(
                revenue=Sum('total_price'),
                bookings=Count('id')
            ).order_by('date')
        else:
            twelve_months_ago = date.today() - timedelta(days=365)
            revenue_data = Booking.objects.filter(
                status__in=['confirmed', 'completed'],
                created_at__date__gte=twelve_months_ago
            ).annotate(month=TruncMonth('created_at')).values('month').annotate(
                revenue=Sum('total_price'),
                bookings=Count('id')
            ).order_by('month')

        chart_data = []
        for item in revenue_data:
            chart_data.append({
                'date': str(item.get('date') or item.get('month')),
                'revenue': str(item['revenue']),
                'bookings': item['bookings']
            })
        return Response(chart_data)


class AdminTopDriversView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        limit = int(request.query_params.get('limit', 10))
        top_drivers = User.objects.filter(role='driver').annotate(
            total_rides=Count('driver_rides', filter=Q(driver_rides__status='completed')),
            total_earnings=Sum('driver_rides__bookings__total_price',
                             filter=Q(driver_rides__bookings__status__in=['confirmed', 'completed']))
        ).filter(total_rides__gt=0).order_by('-total_earnings')[:limit]

        drivers_data = []
        for driver in top_drivers:
            try:
                profile = driver.driverprofile
                car_model = profile.car_model
            except:
                car_model = "N/A"
            drivers_data.append({
                'id': driver.id,
                'username': driver.username,
                'email': driver.email,
                'phone': driver.phone,
                'car_model': car_model,
                'total_rides': driver.total_rides,
                'total_earnings': str(driver.total_earnings or 0),
                'rating': driver.average_rating(),
            })
        return Response(drivers_data)


class AdminRecentActivityView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        limit = int(request.query_params.get('limit', 20))
        recent_bookings = Booking.objects.select_related(
            'passenger', 'ride', 'ride__driver'
        ).order_by('-created_at')[:limit]

        activities = []
        for booking in recent_bookings:
            activities.append({
                'type': 'booking',
                'timestamp': booking.created_at,
                'passenger': booking.passenger.username,
                'driver': booking.ride.driver.username,
                'route': f"{booking.ride.start_location} → {booking.ride.destination}",
                'amount': str(booking.total_price),
                'status': booking.status,
            })
        return Response(activities)


class UpdateProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        user = request.user
        username = request.data.get('username')
        phone = request.data.get('phone')
        if username:
            user.username = username
        if phone:
            user.phone = phone
        user.save()
        return Response({
            "message": "Profile updated successfully",
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "phone": user.phone,
                "role": user.role,
            }
        })


class MyRatingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from rides.models import Rating
        from django.db.models import Avg
        ratings = Rating.objects.filter(reviewee=request.user).select_related(
            'reviewer', 'booking'
        ).order_by('-created_at')
        avg_rating = ratings.aggregate(Avg('score'))['score__avg'] or 0.0
        ratings_data = []
        for rating in ratings:
            ratings_data.append({
                'id': rating.id,
                'score': rating.score,
                'comment': rating.comment,
                'reviewer_name': rating.reviewer.username,
                'created_at': rating.created_at.strftime('%Y-%m-%d'),
            })
        return Response({
            'average_rating': round(avg_rating, 1),
            'total_ratings': ratings.count(),
            'ratings': ratings_data,
        })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_email_verification_code(request):
    user = request.user

    if user.email_verified:
        return Response({"message": "Email already verified"}, status=status.HTTP_200_OK)

    # Generate code
    code = str(random.randint(100000, 999999))
    user.email_verification_code = code
    user.code_created_at = timezone.now()
    user.save()

    # Print code to console (for testing)
    print(f"📧 VERIFICATION CODE FOR {user.email}: {code}")
    
    # Always return success (even if email fails)
    return Response({
        "message": "Verification code sent successfully"
    }, status=status.HTTP_200_OK)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_email_code(request):
    user = request.user
    code = request.data.get('code')

    if not code:
        return Response(
            {"message": "Code is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    if user.email_verified:
        return Response(
            {"message": "Email already verified"},
            status=status.HTTP_200_OK
        )

    if not hasattr(user, 'email_verification_code') or not user.email_verification_code:
        return Response(
            {"message": "No verification code found. Please request a new one."},
            status=status.HTTP_400_BAD_REQUEST
        )

    if user.code_created_at:
        expiry_time = user.code_created_at + timedelta(minutes=10)
        if timezone.now() > expiry_time:
            return Response(
                {"message": "Code expired. Please request a new one."},
                status=status.HTTP_400_BAD_REQUEST
            )

    if user.email_verification_code == code:
        user.email_verified = True
        user.email_verification_code = None
        user.code_created_at = None
        user.save()
        return Response(
            {"message": "Email verified successfully!"},
            status=status.HTTP_200_OK
        )
    else:
        return Response(
            {"message": "Invalid code. Please try again."},
            status=status.HTTP_400_BAD_REQUEST
        )