# Updated accounts/urls.py

from django.urls import path
from .views import (
    RegisterView,
    UserNotificationsView,
    AdminDashboardView,
    SubscriptionView,
    CreateSubscriptionView,
    ProcessPaymentView,
    CheckSubscriptionStatusView,
    CurrentUserView,
    SendEmailVerificationView,
    VerifyEmailView,
    UploadDriverDocumentsView,        # ADD
    GetDriverDocumentsView,            # ADD
    AdminVerifyDriverView,             # ADD
    AdminGetPendingDriversView,        # ADD
    AdminDashboardStatsView,
    AdminRevenueChartView,
    AdminTopDriversView,
    AdminRecentActivityView,
    UpdateProfileView,
    MyRatingsView
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', TokenObtainPairView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('notifications/', UserNotificationsView.as_view(), name='user_notifications'),
    path('admin/dashboard/', AdminDashboardView.as_view()),
    path('profile/update/', UpdateProfileView.as_view(), name='update_profile'),
    path('my-ratings/', MyRatingsView.as_view(), name='my_ratings'),
    
    # User info
    path('me/', CurrentUserView.as_view(), name='current_user'),
    
    # Subscription endpoints
    path('subscription/', SubscriptionView.as_view(), name='subscription'),
    path('subscription/create/', CreateSubscriptionView.as_view(), name='create_subscription'),
    path('subscription/payment/', ProcessPaymentView.as_view(), name='process_payment'),
    path('subscription/status/', CheckSubscriptionStatusView.as_view(), name='subscription_status'),
    
    # Email verification
    path('send-email-verification/', SendEmailVerificationView.as_view(), name='send_email_verification'),
    path('verify-email/<str:token>/', VerifyEmailView.as_view(), name='verify_email'),
    
    # Driver Documents
    path('driver/upload-documents/', UploadDriverDocumentsView.as_view(), name='upload_driver_documents'),
    path('driver/documents/', GetDriverDocumentsView.as_view(), name='get_driver_documents'),
    
    # Admin - Driver Verification
    path('admin/verify-driver/<int:driver_id>/', AdminVerifyDriverView.as_view(), name='admin_verify_driver'),
    path('admin/pending-drivers/', AdminGetPendingDriversView.as_view(), name='admin_pending_drivers'),

    path('admin/dashboard/stats/', AdminDashboardStatsView.as_view(), name='admin_dashboard_stats'),
    path('admin/dashboard/revenue-chart/', AdminRevenueChartView.as_view(), name='admin_revenue_chart'),
    path('admin/dashboard/top-drivers/', AdminTopDriversView.as_view(), name='admin_top_drivers'),
    path('admin/dashboard/recent-activity/', AdminRecentActivityView.as_view(), name='admin_recent_activity'),
]