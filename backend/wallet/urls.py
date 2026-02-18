# Create new file: backend/wallet/urls.py

from django.urls import path
from .views import AddMoneyView, WithdrawMoneyView, WalletBalanceView

urlpatterns = [
    path('add-money/', AddMoneyView.as_view(), name='add_money'),
    path('withdraw/', WithdrawMoneyView.as_view(), name='withdraw_money'),
    path('balance/', WalletBalanceView.as_view(), name='wallet_balance'),
]