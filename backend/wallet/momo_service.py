# backend/wallet/momo_service.py (MOCK VERSION - FREE, NO API KEYS NEEDED)

import uuid
import time
from django.conf import settings

class MTNMoMoService:
    """
    MTN MoMo Mock Service for FREE Testing
    No API keys or registration required!
    
    This simulates MTN MoMo for development/testing
    """
    
    def __init__(self):
        # Test credentials
        self.test_phone = "250793487065"
        self.test_pin = "939871"
        
        # Check if mock mode is enabled
        self.use_mock = getattr(settings, 'USE_MOCK_PAYMENT', True)
    
    def request_to_pay(self, phone_number, amount, currency="RWF"):
        """
        Request payment from customer
        MOCK VERSION - Always succeeds for testing
        
        Args:
            phone_number: Customer phone number
            amount: Amount to charge
            currency: Currency code (default: RWF)
        
        Returns:
            dict: Transaction response
        """
        # Generate unique reference ID
        reference_id = str(uuid.uuid4())
        
        # Clean phone number
        phone = phone_number.replace("+", "").replace(" ", "")
        if not phone.startswith("250"):
            phone = "250" + phone.lstrip("0")
        
        print(f"📱 MOCK PAYMENT REQUEST:")
        print(f"   Phone: {phone}")
        print(f"   Amount: {amount} {currency}")
        print(f"   Reference: {reference_id}")
        
        # Simulate processing delay
        time.sleep(0.5)
        
        # Mock success response
        return {
            "success": True,
            "reference_id": reference_id,
            "message": "Payment request sent. Please check your phone and enter PIN.",
            "status": "pending",
            "mock": True,
            "note": f"MOCK MODE: Simulating payment for {amount} RWF"
        }
    
    def check_payment_status(self, reference_id):
        """
        Check status of payment transaction
        MOCK VERSION - Always returns SUCCESSFUL
        
        Args:
            reference_id: Transaction reference ID
        
        Returns:
            dict: Transaction status (always successful in mock)
        """
        print(f"✅ MOCK STATUS CHECK: {reference_id}")
        
        # Simulate processing delay
        time.sleep(0.3)
        
        # Mock successful payment
        return {
            "success": True,
            "status": "SUCCESSFUL",
            "amount": "10000",  # Mock amount
            "currency": "RWF",
            "financial_transaction_id": str(uuid.uuid4()),
            "mock": True,
            "note": "MOCK MODE: Payment marked as successful"
        }
    
    def request_to_withdraw(self, phone_number, amount, currency="RWF"):
        """
        Send money to user (for withdrawals)
        MOCK VERSION - Always succeeds
        
        Args:
            phone_number: Recipient phone number
            amount: Amount to send
            currency: Currency code
        
        Returns:
            dict: Transaction response
        """
        reference_id = str(uuid.uuid4())
        
        # Clean phone number
        phone = phone_number.replace("+", "").replace(" ", "")
        if not phone.startswith("250"):
            phone = "250" + phone.lstrip("0")
        
        print(f"💸 MOCK WITHDRAWAL:")
        print(f"   To: {phone}")
        print(f"   Amount: {amount} {currency}")
        print(f"   Reference: {reference_id}")
        
        # Simulate processing
        time.sleep(0.5)
        
        return {
            "success": True,
            "reference_id": reference_id,
            "message": "Withdrawal initiated successfully. Funds will be sent shortly.",
            "status": "pending",
            "mock": True,
            "note": f"MOCK MODE: Simulating withdrawal of {amount} RWF to {phone}"
        }
    
    def get_balance(self):
        """Get account balance (MOCK)"""
        return {
            "success": True,
            "available_balance": "1000000",
            "currency": "RWF",
            "mock": True
        }


# ==========================================
# REAL MTN MOMO SERVICE (Requires API Keys)
# ==========================================
# Uncomment and use this when you have real credentials

class MTNMoMoServiceReal:
    """Real MTN MoMo integration - requires API credentials"""
    
    def __init__(self):
        import requests
        self.requests = requests
        self.base_url = "https://sandbox.momodeveloper.mtn.com"
        self.subscription_key = getattr(settings, 'MTN_MOMO_SUBSCRIPTION_KEY', '')
        self.api_user = getattr(settings, 'MTN_MOMO_API_USER', '')
        self.api_key = getattr(settings, 'MTN_MOMO_API_KEY', '')
    
    def get_access_token(self):
        """Get OAuth access token"""
        url = f"{self.base_url}/collection/token/"
        headers = {"Ocp-Apim-Subscription-Key": self.subscription_key}
        auth = (self.api_user, self.api_key)
        
        try:
            response = self.requests.post(url, headers=headers, auth=auth)
            if response.status_code == 200:
                return response.json()['access_token']
        except Exception as e:
            print(f"Error getting token: {e}")
        return None
    
    def request_to_pay(self, phone_number, amount, currency="RWF"):
        """Real payment request to MTN MoMo API"""
        token = self.get_access_token()
        if not token:
            return {"success": False, "error": "Failed to get access token"}
        
        reference_id = str(uuid.uuid4())
        url = f"{self.base_url}/collection/v1_0/requesttopay"
        
        headers = {
            "Authorization": f"Bearer {token}",
            "X-Reference-Id": reference_id,
            "X-Target-Environment": "sandbox",
            "Ocp-Apim-Subscription-Key": self.subscription_key,
            "Content-Type": "application/json"
        }
        
        phone = phone_number.replace("+", "").replace(" ", "")
        if not phone.startswith("250"):
            phone = "250" + phone.lstrip("0")
        
        payload = {
            "amount": str(amount),
            "currency": currency,
            "externalId": str(uuid.uuid4()),
            "payer": {
                "partyIdType": "MSISDN",
                "partyId": phone
            },
            "payerMessage": "Payment for ISHARE ride",
            "payeeNote": f"ISHARE - {amount} {currency}"
        }
        
        try:
            response = self.requests.post(url, headers=headers, json=payload)
            if response.status_code == 202:
                return {
                    "success": True,
                    "reference_id": reference_id,
                    "message": "Payment request sent",
                    "status": "pending"
                }
            return {"success": False, "error": response.text}
        except Exception as e:
            return {"success": False, "error": str(e)}