# backend/wallet/views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .momo_service import MTNMoMoService
import uuid

class AddMoneyView(APIView):
    """Add money to wallet using MTN MoMo"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        amount = request.data.get('amount')
        method = request.data.get('method', 'momo')
        phone_number = request.data.get('phone_number')
        
        if not amount:
            return Response(
                {"error": "Amount is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not phone_number:
            return Response(
                {"error": "Phone number is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            amount_float = float(amount)
            if amount_float < 1000:
                return Response(
                    {"error": "Minimum amount is 1,000 RWF"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except ValueError:
            return Response(
                {"error": "Invalid amount"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Process payment based on method
        if method in ['momo', 'airtel']:
            momo = MTNMoMoService()
            result = momo.request_to_pay(phone_number, amount_float)
            
            if result.get('success'):
                return Response({
                    "message": "Payment request sent. Please check your phone and enter PIN.",
                    "transaction_id": result.get('reference_id'),
                    "amount": amount_float,
                    "method": method,
                    "status": "pending"
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    "error": result.get('error', 'Payment failed'),
                }, status=status.HTTP_400_BAD_REQUEST)
        
        else:
            # Other payment methods (card, bank) - placeholder
            return Response({
                "message": "Payment method not yet supported",
                "transaction_id": str(uuid.uuid4()),
                "amount": amount_float,
                "method": method,
                "status": "pending"
            }, status=status.HTTP_201_CREATED)


class WithdrawMoneyView(APIView):
    """Withdraw money via MTN MoMo"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        amount = request.data.get('amount')
        method = request.data.get('method', 'momo')
        phone_number = request.data.get('phone_number')
        
        if not amount:
            return Response(
                {"error": "Amount is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not phone_number:
            return Response(
                {"error": "Phone number is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            amount_float = float(amount)
            if amount_float < 5000:
                return Response(
                    {"error": "Minimum withdrawal amount is 5,000 RWF"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except ValueError:
            return Response(
                {"error": "Invalid amount"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # TODO: Check if user has sufficient balance
        # For now, proceed with withdrawal
        
        if method in ['momo', 'airtel']:
            momo = MTNMoMoService()
            result = momo.request_to_withdraw(phone_number, amount_float)
            
            if result.get('success'):
                return Response({
                    "message": "Withdrawal request submitted successfully. Funds will be sent shortly.",
                    "transaction_id": result.get('reference_id'),
                    "amount": amount_float,
                    "method": method,
                    "status": "pending"
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    "error": result.get('error', 'Withdrawal failed'),
                }, status=status.HTTP_400_BAD_REQUEST)
        
        else:
            # Other methods - placeholder
            return Response({
                "message": "Withdrawal method not yet supported",
                "transaction_id": str(uuid.uuid4()),
                "amount": amount_float,
                "method": method,
                "status": "pending"
            }, status=status.HTTP_201_CREATED)


class CheckPaymentStatusView(APIView):
    """Check status of a payment transaction"""
    permission_classes = [IsAuthenticated]

    def get(self, request, transaction_id):
        momo = MTNMoMoService()
        result = momo.check_payment_status(transaction_id)
        
        return Response(result)


class WalletBalanceView(APIView):
    """Get wallet balance"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from rides.models import Booking
        
        user = request.user
        balance = 0.0
        
        if user.role == 'driver':
            # Calculate earnings from completed rides
            completed_bookings = Booking.objects.filter(
                ride__driver=user,
                status='completed',
                payment_status='paid'
            )
            balance = sum(float(b.total_price) for b in completed_bookings)
        else:
            # For passengers, balance would be prepaid amount minus spent
            # TODO: Implement wallet balance tracking
            balance = 0.0
        
        return Response({
            "balance": balance,
            "currency": "RWF"
        })