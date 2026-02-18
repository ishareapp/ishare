from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from accounts.permissions import HasActiveSubscription
from accounts.models import Notification
from .models import Ride, Booking, Rating
from .serializers import RideSerializer, BookingSerializer, RatingSerializer
from accounts.notifications import send_push_notification
from accounts.models import DriverProfile
from rest_framework.exceptions import PermissionDenied
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from django.http import HttpResponse
from io import BytesIO


class CreateRideView(generics.CreateAPIView):
    serializer_class = RideSerializer
    permission_classes = [IsAuthenticated, HasActiveSubscription]

    def perform_create(self, serializer):
        # Check if user is a driver
        if self.request.user.role != 'driver':
            raise PermissionDenied("Only drivers can create rides")
        
        # ===================================
        # ADMIN BYPASS: Skip all verification
        # ===================================
        if self.request.user.is_staff or self.request.user.is_superuser:
            print(f"✅ Admin {self.request.user.email} creating ride - bypassing verification")
            
            # Check if admin has driver profile, create if not
            driver_profile, created = DriverProfile.objects.get_or_create(
                user=self.request.user,
                defaults={
                    'national_id': 'ADMIN',
                    'driver_license': 'ADMIN',
                    'car_model': 'Admin Vehicle',
                    'plate_number': 'ADMIN',
                    'seats_available': 4,
                    'is_verified_by_admin': True,
                    'verification_status': 'approved'
                }
            )
            
            # Create ride without requiring car photo
            ride = serializer.save(
                driver=self.request.user,
                car_photo=driver_profile.car_photo_front if driver_profile.car_photo_front else None
            )
            return
        
        # ===================================
        # REGULAR DRIVERS: Check verification
        # ===================================
        try:
            driver_profile = DriverProfile.objects.get(user=self.request.user)
            
            if not driver_profile.is_verified_by_admin:
                raise PermissionDenied("You must be verified by admin before creating rides")
            
            # Save ride with driver and car photo
            ride = serializer.save(
                driver=self.request.user,
                car_photo=driver_profile.car_photo_front if driver_profile.car_photo_front else None
            )
            
        except DriverProfile.DoesNotExist:
            raise PermissionDenied("Driver profile not found. Please upload your documents.")

class SearchRideView(generics.ListAPIView):
    serializer_class = RideSerializer
    permission_classes = [IsAuthenticated, HasActiveSubscription]

    def get_queryset(self):
        start = self.request.query_params.get('start_location')
        destination = self.request.query_params.get('destination')

        queryset = Ride.objects.filter(
            status='active',
            departure_time__gte=timezone.now(),
            available_seats__gt=0
        )

        if start:
            queryset = queryset.filter(start_location__icontains=start)
        if destination:
            queryset = queryset.filter(destination__icontains=destination)

        return queryset

    def get_serializer_context(self):
        """Pass request to serializer for building absolute URLs"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class CreateBookingView(generics.CreateAPIView):
    serializer_class = BookingSerializer
    permission_classes = [IsAuthenticated, HasActiveSubscription]

    def create(self, request, *args, **kwargs):
        ride_id = request.data.get('ride')
        seats_requested = int(request.data.get('seats_booked', 0))
        payment_confirmed = request.data.get('payment_confirmed', False)

        # Check payment confirmation
        if not payment_confirmed:
            return Response(
                {"error": "Payment required before booking"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user is restricted
        if request.user.is_restricted:
            return Response(
                {"error": "Your account is temporarily restricted due to low rating."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get the ride
        try:
            ride = Ride.objects.get(id=ride_id, status='active')
        except Ride.DoesNotExist:
            return Response(
                {"error": "Ride not found"}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check available seats
        if ride.available_seats < seats_requested:
            return Response(
                {"error": "Not enough seats available"}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Calculate total price
        total_price = ride.price_per_seat * seats_requested

        # Create booking
        booking = Booking.objects.create(
            ride=ride,
            passenger=request.user,
            seats_booked=seats_requested,
            total_price=total_price,
            payment_status='paid'
        )

        # Reduce available seats
        ride.available_seats -= seats_requested
        ride.save()

        # Create in-app notifications
        Notification.objects.create(
            user=booking.passenger,
            title="Ride Confirmed 🚗",
            message=f"Your ride to {booking.ride.destination} has been confirmed."
        )
        Notification.objects.create(
            user=booking.ride.driver,
            title="New Booking 📢",
            message=f"{booking.passenger.email} booked {booking.seats_booked} seat(s) for your ride to {booking.ride.destination}."
        )

        # Send push notification to driver
        send_push_notification(
            user=booking.ride.driver,
            title="New Booking! 🎉",
            body=f"{request.user.username} booked {booking.seats_booked} seat(s) for your ride to {booking.ride.destination}",
            data={
                "type": "new_booking",
                "booking_id": str(booking.id),
                "ride_id": str(booking.ride.id),
            }
        )

        # Send push notification to passenger
        send_push_notification(
            user=request.user,
            title="Booking Confirmed! ✅",
            body=f"Your booking for {booking.ride.start_location} → {booking.ride.destination} is confirmed",
            data={
                "type": "booking_confirmed",
                "booking_id": str(booking.id),
            }
        )

        serializer = BookingSerializer(booking)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class UpdateBookingStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id=None):
        if booking_id is None:
            booking_id = request.data.get("booking_id")
        new_status = request.data.get("status")

        # Get booking
        try:
            booking = Booking.objects.get(id=booking_id)
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if user is the driver
        if booking.ride.driver != request.user:
            return Response(
                {"error": "Not allowed"}, 
                status=status.HTTP_403_FORBIDDEN
            )

        # If rejecting, restore seats
        if new_status == "rejected":
            ride = booking.ride
            ride.available_seats += booking.seats_booked
            ride.save()

        # Update booking status
        booking.status = new_status
        booking.save()

        # Send push notifications based on status
        if new_status == 'confirmed':
            send_push_notification(
                user=booking.passenger,
                title="Booking Accepted! 🎊",
                body=f"Driver accepted your booking! Get ready for your ride.",
                data={
                    "type": "booking_accepted",
                    "booking_id": str(booking.id),
                }
            )
        elif new_status == 'rejected':
            send_push_notification(
                user=booking.passenger,
                title="Booking Declined",
                body=f"Unfortunately, the driver declined your booking. Please try another ride.",
                data={
                    "type": "booking_rejected",
                    "booking_id": str(booking.id),
                }
            )

        return Response({"message": f"Booking {new_status} successfully"})


class CompleteRideView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, ride_id):
        # Get ride
        try:
            ride = Ride.objects.get(id=ride_id)
        except Ride.DoesNotExist:
            return Response(
                {"error": "Ride not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if user is the driver
        if ride.driver != request.user:
            return Response(
                {"error": "Not allowed"}, 
                status=status.HTTP_403_FORBIDDEN
            )

        # Mark ride as completed
        ride.status = "completed"
        ride.save()

        # Update all confirmed bookings
        confirmed_bookings = ride.bookings.filter(status="confirmed")
        for booking in confirmed_bookings:
            booking.status = "completed"
            booking.save()

            # Create in-app notifications
            Notification.objects.create(
                user=booking.passenger,
                title="Ride Completed ✅",
                message=f"Your ride to {booking.ride.destination} has been marked as completed."
            )

            # Send push notification to passenger
            send_push_notification(
                user=booking.passenger,
                title="Ride Completed! ⭐",
                body=f"Your ride is complete. Please rate your driver!",
                data={
                    "type": "ride_completed",
                    "booking_id": str(booking.id),
                    "ride_id": str(ride.id),
                }
            )

        # Notification for driver
        Notification.objects.create(
            user=ride.driver,
            title="Ride Completed ✅",
            message=f"Your ride to {ride.destination} has been marked as completed."
        )

        return Response({"message": "Ride completed successfully"})


class CreateRatingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        # Get booking
        try:
            booking = Booking.objects.get(id=booking_id)
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if ride is completed
        if booking.status != "completed":
            return Response(
                {"error": "Ride not completed yet"}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user is part of the booking
        if request.user not in [booking.passenger, booking.ride.driver]:
            return Response(
                {"error": "Not allowed"}, 
                status=status.HTTP_403_FORBIDDEN
            )

        # Determine who is being rated
        reviewee = booking.ride.driver if request.user == booking.passenger else booking.passenger

        # Validate score
        score = int(request.data.get("score"))
        if score < 1 or score > 5:
            return Response(
                {"error": "Score must be between 1 and 5"}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create rating
        rating = Rating.objects.create(
            booking=booking,
            reviewer=request.user,
            reviewee=reviewee,
            score=score,
            comment=request.data.get("comment", "")
        )

        # Evaluate trust level
        reviewee.evaluate_trust_status()

        # Send warnings if necessary
        if reviewee.is_warned and not reviewee.is_restricted:
            Notification.objects.create(
                user=reviewee,
                title="Account Warning ⚠️",
                message="Your rating has fallen below 3. Please improve your behavior."
            )

        if reviewee.is_restricted:
            Notification.objects.create(
                user=reviewee,
                title="Account Restricted 🚫",
                message="Your account is temporarily restricted due to very low rating."
            )

        serializer = RatingSerializer(rating)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MyBookingsView(generics.ListAPIView):
    """Get current user's bookings (for passengers)"""
    serializer_class = BookingSerializer
    permission_classes = [IsAuthenticated, HasActiveSubscription]

    def get_queryset(self):
        return Booking.objects.filter(
            passenger=self.request.user
        ).select_related('ride', 'ride__driver').order_by('-created_at')


class MyRideBookingsView(generics.ListAPIView):
    """Get bookings for rides created by current user (for drivers)"""
    serializer_class = BookingSerializer
    permission_classes = [IsAuthenticated, HasActiveSubscription]

    def get_queryset(self):
        return Booking.objects.filter(
            ride__driver=self.request.user
        ).select_related('ride', 'passenger').order_by('-created_at')


class MyRidesWithBookingsView(APIView):
    """Get all rides created by driver with their bookings"""
    permission_classes = [IsAuthenticated, HasActiveSubscription]

    def get(self, request):
        rides = Ride.objects.filter(
            driver=request.user
        ).prefetch_related('bookings__passenger').order_by('-created_at')
        
        result = []
        for ride in rides:
            ride_data = RideSerializer(ride).data
            bookings = ride.bookings.all()
            
            bookings_data = []
            for booking in bookings:
                booking_data = {
                    'id': booking.id,  # ✅ FIXED: Remove str() to keep as integer
                    'passenger': {
                        'id': str(booking.passenger.id),
                        'username': booking.passenger.username,
                        'email': booking.passenger.email,
                        'phone': booking.passenger.phone,
                    },
                    'passenger_name': booking.passenger.username,  # ✅ ADDED: For chat
                    'seats_booked': booking.seats_booked,
                    'total_price': str(booking.total_price),
                    'status': booking.status,
                    'payment_status': booking.payment_status,
                    'created_at': booking.created_at,
                }
                bookings_data.append(booking_data)
            
            ride_data['bookings'] = bookings_data
            result.append(ride_data)
        
        return Response(result)


class GenerateReceiptView(APIView):
    """Generate PDF receipt for a booking"""
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id):
        try:
            booking = Booking.objects.select_related(
                'ride__driver',
                'passenger'
            ).get(id=booking_id)
            
            # Check if user is part of this booking
            if request.user != booking.passenger and request.user != booking.ride.driver:
                return Response(
                    {"error": "Access denied"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Generate PDF
            buffer = BytesIO()
            pdf = self._generate_receipt_pdf(buffer, booking)
            buffer.seek(0)
            
            # Return PDF
            response = HttpResponse(buffer, content_type='application/pdf')
            response['Content-Disposition'] = f'attachment; filename="receipt_{booking.id}.pdf"'
            
            return response
            
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )

    def _generate_receipt_pdf(self, buffer, booking):
        """Generate the actual PDF receipt"""
        doc = SimpleDocTemplate(buffer, pagesize=letter)
        story = []
        styles = getSampleStyleSheet()
        
        # Custom styles
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#1E3A8A'),
            spaceAfter=30,
            alignment=TA_CENTER
        )
        
        # Title
        story.append(Paragraph("ISHARE", title_style))
        story.append(Paragraph("Ride Receipt", styles['Heading2']))
        story.append(Spacer(1, 0.3*inch))
        
        # Receipt Info
        receipt_data = [
            ['Receipt #:', f'ISHARE-{booking.id}'],
            ['Date:', booking.created_at.strftime('%Y-%m-%d %H:%M')],
            ['Status:', booking.status.upper()],
        ]
        
        receipt_table = Table(receipt_data, colWidths=[2*inch, 4*inch])
        receipt_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.grey),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
        ]))
        story.append(receipt_table)
        story.append(Spacer(1, 0.3*inch))
        
        # Ride Details
        story.append(Paragraph("Ride Details", styles['Heading3']))
        story.append(Spacer(1, 0.1*inch))
        
        ride_data = [
            ['From:', booking.ride.start_location],
            ['To:', booking.ride.destination],
            ['Departure:', booking.ride.departure_time.strftime('%Y-%m-%d %H:%M')],
            ['Driver:', booking.ride.driver.username],
            ['Driver Phone:', booking.ride.driver.phone],
            ['Passenger:', booking.passenger.username],
            ['Passenger Phone:', booking.passenger.phone],
        ]
        
        ride_table = Table(ride_data, colWidths=[2*inch, 4*inch])
        ride_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.grey),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        story.append(ride_table)
        story.append(Spacer(1, 0.3*inch))
        
        # Payment Summary
        story.append(Paragraph("Payment Summary", styles['Heading3']))
        story.append(Spacer(1, 0.1*inch))
        
        payment_data = [
            ['Seats Booked:', str(booking.seats_booked)],
            ['Price per Seat:', f'{booking.ride.price_per_seat} RWF'],
            ['', ''],
            ['Total Amount:', f'{booking.total_price} RWF'],
        ]
        
        payment_table = Table(payment_data, colWidths=[4*inch, 2*inch])
        payment_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.grey),
            ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
            ('FONTNAME', (0, 3), (-1, 3), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 3), (-1, 3), 14),
            ('TEXTCOLOR', (0, 3), (-1, 3), colors.HexColor('#1E3A8A')),
            ('LINEABOVE', (0, 3), (-1, 3), 2, colors.HexColor('#1E3A8A')),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        story.append(payment_table)
        story.append(Spacer(1, 0.5*inch))
        
        # Footer
        footer_style = ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=8,
            textColor=colors.grey,
            alignment=TA_CENTER
        )
        story.append(Paragraph("Thank you for riding with ISHARE!", footer_style))
        story.append(Paragraph("Ride Smart. Ride Together.", footer_style))
        
        # Build PDF
        doc.build(story)
        return buffer


class GetReceiptDataView(APIView):
    """Get receipt data as JSON"""
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id):
        try:
            booking = Booking.objects.select_related(
                'ride__driver',
                'passenger'
            ).get(id=booking_id)
            
            # Check access
            if request.user != booking.passenger and request.user != booking.ride.driver:
                return Response(
                    {"error": "Access denied"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            data = {
                'receipt_number': f'ISHARE-{booking.id}',
                'date': booking.created_at,
                'status': booking.status,
                'ride': {
                    'from': booking.ride.start_location,
                    'to': booking.ride.destination,
                    'departure': booking.ride.departure_time,
                    'driver': {
                        'name': booking.ride.driver.username,
                        'phone': booking.ride.driver.phone,
                    },
                    'passenger': {
                        'name': booking.passenger.username,
                        'phone': booking.passenger.phone,
                    }
                },
                'payment': {
                    'seats_booked': booking.seats_booked,
                    'price_per_seat': str(booking.ride.price_per_seat),
                    'total_amount': str(booking.total_price),
                }
            }
            
            return Response(data)
            
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class AcceptBookingView(APIView):
    """Accept a pending booking"""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        try:
            booking = Booking.objects.select_related('ride', 'passenger').get(id=booking_id)
            
            # Only the driver can accept
            if booking.ride.driver != request.user:
                return Response(
                    {"error": "Only the ride driver can accept bookings"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if booking is pending
            if booking.status != 'pending':
                return Response(
                    {"error": f"Booking is already {booking.status}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Accept booking
            booking.status = 'confirmed'
            booking.save()
            
            # Send notification to passenger
            send_push_notification(
                user=booking.passenger,
                title="Booking Confirmed! ✅",
                body=f"Your booking for {booking.ride.start_location} → {booking.ride.destination} has been confirmed!",
                data={"type": "booking_confirmed", "booking_id": str(booking.id)}
            )
            
            return Response({
                "message": "Booking accepted successfully",
                "booking": BookingSerializer(booking).data
            })
            
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class RejectBookingView(APIView):
    """Reject a pending booking"""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        try:
            booking = Booking.objects.select_related('ride', 'passenger').get(id=booking_id)
            
            # Only the driver can reject
            if booking.ride.driver != request.user:
                return Response(
                    {"error": "Only the ride driver can reject bookings"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if booking is pending
            if booking.status != 'pending':
                return Response(
                    {"error": f"Booking is already {booking.status}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Reject booking
            booking.status = 'cancelled'
            booking.save()
            
            # Restore seats to ride
            booking.ride.available_seats += booking.seats_booked
            booking.ride.save()
            
            # Send notification to passenger
            send_push_notification(
                user=booking.passenger,
                title="Booking Rejected",
                body=f"Your booking for {booking.ride.start_location} → {booking.ride.destination} was not accepted.",
                data={"type": "booking_rejected", "booking_id": str(booking.id)}
            )
            
            return Response({
                "message": "Booking rejected",
                "booking": BookingSerializer(booking).data
            })
            
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found"},
                status=status.HTTP_404_NOT_FOUND
            )
class ScheduleBookingView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        # Handle scheduled booking logic
        # Store schedule_type, start_date, end_date
        # Create recurring bookings based on schedule_type
        pass            
class CreateScheduledRideView(APIView):
    """Create recurring rides (daily, weekend, monthly)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        start_location = request.data.get('start_location')
        destination = request.data.get('destination')
        departure_time_str = request.data.get('departure_time')
        price_per_seat = request.data.get('price_per_seat')
        available_seats = request.data.get('available_seats')
        schedule_type = request.data.get('schedule_type')  # daily, weekend, monthly
        end_date_str = request.data.get('end_date')
        
        if not all([start_location, destination, departure_time_str, price_per_seat, 
                    available_seats, schedule_type, end_date_str]):
            return Response(
                {"error": "All fields required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            departure_time = datetime.fromisoformat(departure_time_str.replace('Z', '+00:00'))
            end_date = datetime.fromisoformat(end_date_str.replace('Z', '+00:00'))
            
            created_rides = []
            current_date = departure_time
            
            while current_date <= end_date:
                # Check schedule type
                should_create = False
                
                if schedule_type == 'daily':
                    # Monday to Friday (0-4)
                    if current_date.weekday() < 5:
                        should_create = True
                        
                elif schedule_type == 'weekend':
                    # Saturday and Sunday (5-6)
                    if current_date.weekday() >= 5:
                        should_create = True
                        
                elif schedule_type == 'monthly':
                    # Same day each month
                    should_create = True
                    
                if should_create:
                    ride = Ride.objects.create(
                        driver=request.user,
                        start_location=start_location,
                        destination=destination,
                        departure_time=current_date,
                        price_per_seat=price_per_seat,
                        available_seats=available_seats,
                        status='active'
                    )
                    created_rides.append({
                        'id': ride.id,
                        'date': current_date.strftime('%Y-%m-%d'),
                    })
                
                # Increment date
                if schedule_type == 'monthly':
                    current_date = current_date + relativedelta(months=1)
                else:
                    current_date = current_date + timedelta(days=1)
            
            return Response({
                "message": f"{len(created_rides)} rides created successfully",
                "rides_created": len(created_rides),
                "rides": created_rides
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

class UpdateLocationView(APIView):
    """Update user's real-time location"""
    def post(self, request):
        # Store lat/lng in cache or DB
        pass

class GetLocationView(APIView):
    """Get other person's location"""
    def get(self, request, booking_id):
        # Return driver & passenger locations
        pass

class SOSAlertView(APIView):
    """Handle SOS emergency"""
    def post(self, request):
        # Send SMS/email to emergency contacts
        # Alert police
        # Notify support team
        pass        