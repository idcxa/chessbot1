FROM rust:1.55.0-buster as builder
# just copy absolutely everything to /app
WORKDIR /app
COPY . /app
RUN ls
WORKDIR /app/engines/ctengine-rs/
RUN ls
RUN apt-get update && apt-get upgrade -y && apt-get install -y build-essential git clang llvm-dev libclang-dev libssl-dev pkg-config libpq-dev brotli ruby
RUN cargo build --release
#RUN rm ../ctengine
RUN ls ../
WORKDIR /app
RUN ls
RUN ls engines/

FROM python:3.8-slim-buster
WORKDIR /app
COPY . /app
RUN apt-get update && apt-get upgrade -y && apt-get install -y ruby
# stop python making annoying .pyc files
ENV PYTHONDONTWRITEBYTECODE=1

# no buffering for better logging
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN python -m pip install -r requirements.txt


#RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
#USER appuser

#COPY /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
#ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
#ADD ./engines/ctengine .
COPY --from=builder /app/engines/ctengine-rs/target/release/ctengine /app/engines/
CMD ["python", "lichess-bot.py", "-u"]
