FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN python manage.py collectstatic --noinput
CMD ["daphne", "-b", "0.0.0.0", "-p", "8080", "config.asgi:application"]
