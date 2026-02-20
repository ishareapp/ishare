FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN python manage.py collectstatic --noinput
CMD python manage.py migrate && daphne -b 0.0.0.0 -p $PORT config.asgi:application