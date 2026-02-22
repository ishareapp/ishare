from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse

def api_root(request):
    return JsonResponse({
        "message": "Ride Sharing API is running",
        "endpoints": {
            "accounts": "/api/accounts/",
            "rides": "/api/rides/",
            "chat": "/api/chat/",
            "wallet": "/api/wallet/",
            "admin": "/admin/",
        }
    })

urlpatterns = [
    path('', api_root),
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.urls')),
    path('api/rides/', include('rides.urls')),
    path('api/chat/', include('chat.urls')),
    path('api/wallet/', include('wallet.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)