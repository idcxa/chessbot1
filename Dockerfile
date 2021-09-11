FROM python:3.8-slim-buster

# stop python making annoying .pyc files
ENV PYTHONDONTWRITEBYTECODE=1

# no buffering for better logging
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN python -m pip install -r requirements.txt

# just copy absolutely everything to /app
WORKDIR /app
COPY . /app

RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
CMD ["python", "lichess-bot.py"]
