FROM python:alpine

ENV DEV_UID='' \
    DEV_GID='' \
    DATA_DIR='/conan_data' \
    DEFAULT_RUN_USER='conan' \
    DEFAULT_RUN_COMMAND='/usr/local/bin/conan_server'\
    \
    ADMIN_USER='admin' \
    ADMIN_PASSWORD='1234' \
    JWT_SECRET='nnnSZLAMDwCFlUvRXdVvvFfP' \
    UPDOWN_SECRET='qUbaOgbxztBagqNUoZpKuUrf'

VOLUME $DATA_DIR

RUN apk add --update \
        gettext \
        curl && \
    curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64" && \
    chmod +x /usr/local/bin/gosu && \
    rm -rf /var/cache/apk/*


RUN pip install --no-cache-dir conan
RUN adduser -S $DEFAULT_RUN_USER -h /var/lib/conan -s /bin/sh

# Run uwsgi listening on port 9300
EXPOSE 9300

COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/conan_conf /conan_conf

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/conan_server"]
