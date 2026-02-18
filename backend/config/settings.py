from pathlib import Path
from decouple import config
import firebase_admin
from firebase_admin import credentials
import os
import json

BASE_DIR = Path(__file__).resolve().parent.parent

# ======================
# Django basic settings
# ======================
SECRET_KEY = config('SECRET_KEY', default='unsafe-secret')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = []

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'rest_framework',
    'corsheaders',
    'accounts',
    'rides',
    'chat',
    'channels',
    'wallet',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = "config.asgi.application"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
os.makedirs(MEDIA_ROOT, exist_ok=True)

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
AUTH_USER_MODEL = 'accounts.User'

# ======================
# JWT Authentication
# ======================
from datetime import timedelta
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

# ======================
# Email
# ======================
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend' 
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'murenzicharles24@gmail.com'
EMAIL_HOST_PASSWORD = 'flim xcom shed shwe'
SITE_URL = 'http://127.0.0.1:8000' 

# ======================
# CORS
# ======================
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_METHODS = ['DELETE','GET','OPTIONS','PATCH','POST','PUT']
CORS_ALLOW_HEADERS = [
    'accept','accept-encoding','authorization','content-type',
    'dnt','origin','user-agent','x-csrftoken','x-requested-with'
]

# ======================
# Firebase Admin
# ======================
# Option 1: Read from local file (for development)
local_firebase_path = os.path.join(BASE_DIR, 'firebase-credentials.json')

# Option 2: Read from environment variable (for deployment)
firebase_env = os.environ.get("FIREBASE_CREDENTIALS")

if firebase_env:
    try:
        cred = credentials.Certificate(json.loads(firebase_env))
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized from environment variable")
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
elif os.path.exists(local_firebase_path):
    try:
        cred = credentials.Certificate(local_firebase_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized from local file")
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
else:
    print("⚠️ Firebase credentials not found! Firebase will not work")

# ======================
# Channels
# ======================
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",
    },
}

# ======================
# Other settings
# ======================
USE_MOCK_PAYMENT = True
