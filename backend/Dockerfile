FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN python manage.py collectstatic --noinput
CMD python manage.py migrate && gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 2