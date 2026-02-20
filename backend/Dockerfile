FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "config.asgi:application"]