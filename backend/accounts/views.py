from rest_framework import generics
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, NotificationSerializer
from .models import Notification  # make sure Notification is imported
from django.db.models import Sum
from rest_framework.permissions import IsAdminUser
from accounts.models import User
from .models import Subscription
from datetime import date, timedelta
from rest_framework import status
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import random
from .models import User
import secrets
from rest_framework.parsers import MultiPartParser, FormParser
from datetime import datetime
from .models import DriverProfile
from rides.models import Ride, Booking, Rating  # ADD Rating here
from django.db.models import Sum, Count, Q, Avg
from django.db.models.functions import TruncDate, TruncMonth
from datetime import datetime, timedelta
from decimal import Decimal
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes

User = get_user_model()
import logging

logger = logging.getLogger(__name__)


class ProcessPaymentView(APIView):
    """Process subscription payment"""
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

        # Validate amount
        if amount != 5000:
            return Response(
                {"error": "Invalid amount. Subscription costs 5000 RWF"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # TODO: Integrate with actual payment gateway
        # For now, we'll simulate payment success
        # In production, you would integrate with:
        # - MTN Mobile Money API
        # - Airtel Money API
        # - Or use a payment aggregator like Flutterwave, Paystack, etc.

        payment_successful = self._process_mobile_money_payment(
            phone_number, payment_method, amount
        )

        if not payment_successful:
            return Response(
                {"error": "Payment processing failed. Please try again."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get or create subscription
        try:
            subscription = Subscription.objects.get(user=request.user)
            
            # Renew subscription
            if subscription.expiry_date < date.today():
                # Expired - start from today
                subscription.expiry_date = date.today() + timedelta(days=30)
            else:
                # Active - extend from expiry date
                subscription.expiry_date += timedelta(days=30)
            
            subscription.is_active = True
            subscription.is_trial = False
            subscription.save()

        except Subscription.DoesNotExist:
            # Create new paid subscription
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
        """
        Process mobile money payment
        
        TODO: Integrate with actual payment gateway
        
        For MTN Mobile Money:
        - API Endpoint: https://momoapi.mtn.com/
        - Documentation: https://momodeveloper.mtn.com/
        
        For Airtel Money:
        - Contact Airtel for API access
        
        For now, this simulates a successful payment
        """
        
        # Log payment attempt
        logger.info(
            f"Payment attempt: {payment_method} - {phone_number} - {amount} RWF"
        )

        # TODO: Replace with actual payment gateway integration
        # Example for MTN Mobile Money:
        """
        import requests
        
        headers = {
            "Authorization": "Bearer YOUR_ACCESS_TOKEN",
            "X-Target-Environment": "production",
            "Content-Type": "application/json",
        }
        
        payload = {
            "amount": str(amount),
            "currency": "RWF",
            "externalId": f"sub_{request.user.id}_{int(time.time())}",
            "payer": {
                "partyIdType": "MSISDN",
                "partyId": phone_number
            },
            "payerMessage": "ISHARE Subscription Payment",
            "payeeNote": "Monthly subscription - 5000 RWF"
        }
        
        response = requests.post(
            "https://momoapi.mtn.com/collection/v1_0/requesttopay",
            json=payload,
            headers=headers
        )
        
        return response.status_code == 202
        """

        # For development: simulate success
        # In production, remove this and use actual payment gateway
        return True


class CheckSubscriptionStatusView(APIView):
    """Check subscription status and days remaining"""
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

# Update RegisterView in accounts/views.py

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Create automatic 30-day free trial subscription
        Subscription.objects.create(
            user=user,
            plan_type=user.role,
            expiry_date=date.today() + timedelta(days=30),
            is_active=True,
            is_trial=True,
        )

        # Send WELCOME email (not verification)
        try:
            send_mail(
                subject="Welcome to ISHARE! 🎉",
                message=f"""
Hello {user.username},

Welcome to ISHARE - Ride Smart. Ride Together!

Thank you for joining our ride-sharing community. We're excited to have you on board!

Your account has been created successfully with the following details:
- Email: {user.email}
- Role: {user.role.capitalize()}

Next steps:
1. Verify your email address (you'll be prompted in the app)
2. Complete your profile
3. {"Start creating rides!" if user.role == "driver" else "Find and book rides!"}

If you have any questions, feel free to reach out to our support team.

Happy riding!

Best regards,
The ISHARE Team
                """,
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[user.email],
                fail_silently=True,
            )
            print(f"✅ Welcome email sent to {user.email}")
        except Exception as e:
            print(f"⚠️  Failed to send welcome email: {e}")

        refresh = RefreshToken.for_user(user)

        return Response({
            "user": serializer.data,
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        })

class UserNotificationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # assuming Notification model has a foreign key 'user'
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

        # Blocked users (rating < 2.5)
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
    """Get current user's subscription"""
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
    """Create/Activate subscription for user"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from datetime import date, timedelta
        
        plan_type = request.data.get("plan_type")
        is_trial = request.data.get("is_trial", True)

        if plan_type not in ['passenger', 'driver']:
            return Response(
                {"error": "Invalid plan type"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if subscription already exists
        if Subscription.objects.filter(user=request.user).exists():
            return Response(
                {"error": "Subscription already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create subscription with 30 days trial
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

        # Add this class to your accounts/views.py (at the end, before the last line)

class CurrentUserView(APIView):
    """Get current authenticated user's information"""
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
            "is_superuser": user.is_superuser,  # ADD THIS
            "is_staff": user.is_staff,          # ADD THIS
        })
class SendEmailVerificationView(APIView):
    """Send email verification link"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        
        if user.email_verified:
            return Response(
                {"message": "Email already verified"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate verification token
        token = secrets.token_urlsafe(32)
        user.email_verification_token = token
        user.save()
        
        # Create verification link - IMPORTANT: No trailing slash in URL
        verification_link = f"{settings.SITE_URL}/api/accounts/verify-email/{token}"  # ← Removed trailing /
        
        # Send email
        subject = "Verify Your ISHARE Account"
        message = f"""
Hello {user.username},

Thank you for registering with ISHARE!

Please verify your email address by clicking the link below:
{verification_link}

This link will expire in 24 hours.

If you didn't create this account, please ignore this email.

Best regards,
The ISHARE Team
        """
        
        try:
            send_mail(
                subject,
                message,
                settings.EMAIL_HOST_USER,
                [user.email],
                fail_silently=False,
            )
            
            return Response(
                {"message": "Verification email sent successfully"},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {"error": f"Failed to send email: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class VerifyEmailView(APIView):
    """Verify email with token"""
    permission_classes = [AllowAny]

    def get(self, request, token):
        try:
            user = User.objects.get(email_verification_token=token)
            
            if user.email_verified:
                return Response(
                    {"message": "Email already verified"},
                    status=status.HTTP_200_OK
                )
            
            # Mark as verified
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
    """Upload driver documents"""
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        user = request.user
        
        # Check if user is a driver
        if user.role != 'driver':
            return Response(
                {"error": "Only drivers can upload documents"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            driver_profile = DriverProfile.objects.get(user=user)
        except DriverProfile.DoesNotExist:
            # Create driver profile if doesn't exist
            driver_profile = DriverProfile.objects.create(
                user=user,
                national_id='',
                driver_license='',
                car_model='',
                plate_number='',
                seats_available=4,
            )
        
        # ===================================
        # ADMIN BYPASS: Can upload partial documents
        # ===================================
        is_admin = user.is_staff or user.is_superuser
        
        # Update documents (upload any, not all required)
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
        
        # ===================================
        # ADMIN: Auto-approve immediately
        # ===================================
        if is_admin:
            driver_profile.verification_status = 'approved'
            driver_profile.is_verified_by_admin = True
            driver_profile.documents_uploaded_at = datetime.now()
            driver_profile.save()
            
            print(f"✅ Admin {user.email} documents auto-approved")
            
            return Response(
                {
                    "message": "Admin documents uploaded and auto-approved! You can now create rides.",
                    "verification_status": driver_profile.verification_status,
                    "is_admin": True
                },
                status=status.HTTP_200_OK
            )
        
        # ===================================
        # REGULAR USERS: Pending approval
        # ===================================
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
    """Get driver's document upload status"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        
        if user.role != 'driver':
            return Response(
                {"error": "Only drivers can access this"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # ===================================
        # ADMIN BYPASS: Always verified
        # ===================================
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
        
        # ===================================
        # REGULAR USERS: Check actual status
        # ===================================
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
    """Admin endpoint to approve/reject driver"""
    permission_classes = [IsAdminUser]

    def post(self, request, driver_id):
        action = request.data.get('action')  # 'approve' or 'reject'
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
            
            # Send notification to driver
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
    """Get all drivers pending verification"""
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
    """Complete admin dashboard statistics"""
    permission_classes = [IsAdminUser]

    def get(self, request):
        # Date filters
        today = date.today()
        last_30_days = today - timedelta(days=30)
        last_7_days = today - timedelta(days=7)

        # ==================
        # USER STATISTICS
        # ==================
        total_users = User.objects.count()
        total_drivers = User.objects.filter(role="driver").count()
        total_passengers = User.objects.filter(role="passenger").count()
        
        # New users (last 30 days)
        new_users_30d = User.objects.filter(
            date_joined__gte=last_30_days
        ).count()
        
        # Verified drivers
        verified_drivers = DriverProfile.objects.filter(
            is_verified_by_admin=True
        ).count()
        
        pending_verification = DriverProfile.objects.filter(
            verification_status='pending'
        ).count()

        # ==================
        # RIDE STATISTICS
        # ==================
        total_rides = Ride.objects.count()
        active_rides = Ride.objects.filter(status="active").count()
        completed_rides = Ride.objects.filter(status="completed").count()
        
        # Rides last 30 days
        rides_30d = Ride.objects.filter(
            created_at__gte=last_30_days
        ).count()

        # ==================
        # BOOKING STATISTICS
        # ==================
        total_bookings = Booking.objects.count()
        confirmed_bookings = Booking.objects.filter(status='confirmed').count()
        pending_bookings = Booking.objects.filter(status='pending').count()
        
        # Bookings last 30 days
        bookings_30d = Booking.objects.filter(
            created_at__gte=last_30_days
        ).count()

        # ==================
        # REVENUE STATISTICS
        # ==================
        
        # Total revenue from completed bookings
        total_revenue = Booking.objects.filter(
            status__in=['confirmed', 'completed']
        ).aggregate(
            total=Sum('total_price')
        )['total'] or Decimal('0.00')
        
        # Revenue last 30 days
        revenue_30d = Booking.objects.filter(
            status__in=['confirmed', 'completed'],
            created_at__gte=last_30_days
        ).aggregate(
            total=Sum('total_price')
        )['total'] or Decimal('0.00')
        
        # Revenue last 7 days
        revenue_7d = Booking.objects.filter(
            status__in=['confirmed', 'completed'],
            created_at__gte=last_7_days
        ).aggregate(
            total=Sum('total_price')
        )['total'] or Decimal('0.00')
        
        # Revenue today
        revenue_today = Booking.objects.filter(
            status__in=['confirmed', 'completed'],
            created_at__date=today
        ).aggregate(
            total=Sum('total_price')
        )['total'] or Decimal('0.00')
        
        # Subscription revenue
        subscription_revenue = Subscription.objects.filter(
            is_active=True,
            is_trial=False
        ).count() * 5000  # 5000 RWF per subscription
        
        # Average booking value
        avg_booking_value = Booking.objects.filter(
            status__in=['confirmed', 'completed']
        ).aggregate(
            avg=Avg('total_price')
        )['avg'] or Decimal('0.00')

        # ==================
        # SUBSCRIPTION STATS
        # ==================
        active_subscriptions = Subscription.objects.filter(
            is_active=True,
            expiry_date__gte=today
        ).count()
        
        trial_subscriptions = Subscription.objects.filter(
            is_trial=True,
            is_active=True
        ).count()
        
        paid_subscriptions = Subscription.objects.filter(
            is_trial=False,
            is_active=True
        ).count()
        
        expired_subscriptions = Subscription.objects.filter(
            expiry_date__lt=today
        ).count()

        # ==================
        # RATING STATISTICS
        # ==================
        total_ratings = Rating.objects.count()
        avg_driver_rating = Rating.objects.aggregate(
            avg=Avg('score')
        )['avg'] or 0.0

        # ==================
        # GROWTH METRICS
        # ==================
        
        # Users growth (compare to previous period)
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
    """Get revenue data for charts (daily/monthly)"""
    permission_classes = [IsAdminUser]

    def get(self, request):
        period = request.query_params.get('period', 'daily')  # 'daily' or 'monthly'
        
        if period == 'daily':
            # Last 30 days daily revenue
            thirty_days_ago = date.today() - timedelta(days=30)
            
            revenue_data = Booking.objects.filter(
                status__in=['confirmed', 'completed'],
                created_at__date__gte=thirty_days_ago
            ).annotate(
                date=TruncDate('created_at')
            ).values('date').annotate(
                revenue=Sum('total_price'),
                bookings=Count('id')
            ).order_by('date')
            
        else:  # monthly
            # Last 12 months
            twelve_months_ago = date.today() - timedelta(days=365)
            
            revenue_data = Booking.objects.filter(
                status__in=['confirmed', 'completed'],
                created_at__date__gte=twelve_months_ago
            ).annotate(
                month=TruncMonth('created_at')
            ).values('month').annotate(
                revenue=Sum('total_price'),
                bookings=Count('id')
            ).order_by('month')
        
        # Format data for charts
        chart_data = []
        for item in revenue_data:
            chart_data.append({
                'date': str(item.get('date') or item.get('month')),
                'revenue': str(item['revenue']),
                'bookings': item['bookings']
            })
        
        return Response(chart_data)


class AdminTopDriversView(APIView):
    """Get top performing drivers"""
    permission_classes = [IsAdminUser]

    def get(self, request):
        limit = int(request.query_params.get('limit', 10))
        
        # Get drivers with most completed rides
        top_drivers = User.objects.filter(
            role='driver'
        ).annotate(
            total_rides=Count('driver_rides', filter=Q(driver_rides__status='completed')),
            total_earnings=Sum('driver_rides__bookings__total_price', 
                             filter=Q(driver_rides__bookings__status__in=['confirmed', 'completed']))
        ).filter(
            total_rides__gt=0
        ).order_by('-total_earnings')[:limit]
        
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
    """Get recent platform activity"""
    permission_classes = [IsAdminUser]

    def get(self, request):
        limit = int(request.query_params.get('limit', 20))
        
        # Recent bookings
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
    """Update user profile (username, phone)"""
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
    """Get all ratings received by current user"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from rides.models import Rating
        from django.db.models import Avg
        
        # Get all ratings where user is the reviewee
        ratings = Rating.objects.filter(reviewee=request.user).select_related(
            'reviewer', 'booking'
        ).order_by('-created_at')
        
        # Calculate average
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
def send_email_verification_code(request):
    """
    Generate and send a 6-digit verification code to user's email
    """
    user = request.user
    
    if user.email_verified:
        return Response(
            {"message": "Email already verified"},
            status=status.HTTP_200_OK
        )
    
    # Generate 6-digit code
    code = str(random.randint(100000, 999999))
    
    # Store code in user model (you'll need to add these fields)
    user.email_verification_code = code
    user.code_created_at = timezone.now()
    user.save()
    
    # Send email
    subject = "ISHARE - Email Verification Code"
    message = f"""
    Hello {user.username},
    
    Your ISHARE email verification code is:
    
    {code}
    
    This code will expire in 10 minutes.
    
    If you didn't request this code, please ignore this email.
    
    Best regards,
    ISHARE Team
    Made in Rwanda 🇷🇼
    """
    
    try:
        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [user.email],
            fail_silently=False,
        )
        
        return Response(
            {"message": "Verification code sent successfully"},
            status=status.HTTP_200_OK
        )
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_email_code(request):
    """
    Verify the 6-digit code entered by user
    """
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
    
    # Check if code exists
    if not hasattr(user, 'email_verification_code') or not user.email_verification_code:
        return Response(
            {"message": "No verification code found. Please request a new one."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if code expired (10 minutes)
    if user.code_created_at:
        expiry_time = user.code_created_at + timedelta(minutes=10)
        if timezone.now() > expiry_time:
            return Response(
                {"message": "Code expired. Please request a new one."},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    # Verify code
    if user.email_verification_code == code:
        user.email_verified = True
        user.email_verification_code = None  # Clear the code
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



























































































           