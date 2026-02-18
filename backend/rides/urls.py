# Updated rides/urls.py

from django.urls import path
from .views import (
    CreateRideView,
    SearchRideView,
    CreateBookingView,
    UpdateBookingStatusView,
    CompleteRideView,
    CreateRatingView,
    MyBookingsView,  # ADD THIS
    MyRideBookingsView,  # ADD THIS
    MyRidesWithBookingsView,
    GenerateReceiptView,
    GetReceiptDataView,
    AcceptBookingView,
    RejectBookingView,
)

urlpatterns = [
    path('create/', CreateRideView.as_view(), name='create_ride'),
    path('search/', SearchRideView.as_view(), name='search_ride'),
    path('book/', CreateBookingView.as_view(), name='create_booking'),
    path('booking/<int:booking_id>/update/', UpdateBookingStatusView.as_view(), name='update_booking_status'),
    path('complete/<int:ride_id>/', CompleteRideView.as_view(), name='complete_ride'),
    path('rate/<int:booking_id>/', CreateRatingView.as_view(), name='create_rating'),
    path('my-rides-with-bookings/', MyRidesWithBookingsView.as_view(), name='my_rides_with_bookings'),
    path('receipt/<int:booking_id>/', GenerateReceiptView.as_view(), name='generate_receipt'),
    path('receipt/<int:booking_id>/data/', GetReceiptDataView.as_view(), name='receipt_data'),
    path('bookings/<int:booking_id>/accept/', AcceptBookingView.as_view(), name='accept_booking'),
    path('bookings/<int:booking_id>/reject/', RejectBookingView.as_view(), name='reject_booking'),
    
    # Booking history
    path('my-bookings/', MyBookingsView.as_view(), name='my_bookings'),  # ADD THIS
    path('my-ride-bookings/', MyRideBookingsView.as_view(), name='my_ride_bookings'),  # ADD THIS
]