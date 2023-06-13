FROM debian:12
RUN apt-get update \
  && apt-get install --no-install-recommends -fy \
    openssh-client=1:8.4p1-5+deb11u1 \
    openssh-server=1:8.4p1-5+deb11u1 \
    libqrencode4=4.1.1-1 \
    libpam-google-authenticator=20191231-2 \
    fail2ban=0.11.2-2 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && /bin/sh -c "rm -f /etc/ssh/ssh_host_*_key"
COPY sshd.local /etc/fail2ban/jail.d/sshd.local
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT /entrypoint.sh
