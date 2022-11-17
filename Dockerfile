FROM debian:latest
RUN apt-get update \
  && apt-get install -fy \
    openssh-server \
    libpam-google-authenticator \
    fail2ban \
  && /bin/sh -c "rm -f /etc/ssh/ssh_host_*_key"
COPY entrypoint.sh /
ENTRYPOINT /entrypoint.sh

