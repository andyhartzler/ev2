# Mautic 6 for Railway
FROM mautic/mautic:6-apache

LABEL maintainer="MO Young Democrats"

# PHP Configuration
ENV PHP_INI_VALUE_MEMORY_LIMIT=512M
ENV PHP_INI_VALUE_UPLOAD_MAX_FILESIZE=64M
ENV PHP_INI_VALUE_POST_MAX_SIZE=64M
ENV PHP_INI_VALUE_MAX_EXECUTION_TIME=300
ENV PHP_INI_VALUE_DATE_TIMEZONE=America/Chicago

# Mautic Configuration
ENV DOCKER_MAUTIC_ROLE=mautic_web
ENV MAUTIC_RUN_CRON_JOBS=true

# Queue settings (doctrine = simple, no RabbitMQ needed)
ENV MAUTIC_MESSENGER_DSN_EMAIL=doctrine://default
ENV MAUTIC_MESSENGER_DSN_HIT=doctrine://default
ENV MAUTIC_MESSENGER_DSN_FAILED=doctrine://default

# Railway injects PORT - Apache needs to listen on it
# Default to 80 if PORT not set
ARG PORT=80
ENV PORT=${PORT}
ENV APACHE_PORT=${PORT}

# Update Apache to listen on the correct port
RUN sed -i "s/Listen 80/Listen \${APACHE_PORT}/g" /etc/apache2/ports.conf && \
    sed -i "s/:80/:\${APACHE_PORT}/g" /etc/apache2/sites-available/000-default.conf

# Copy custom themes and plugins
COPY --chown=www-data:www-data themes/ /var/www/html/docroot/themes/
COPY --chown=www-data:www-data plugins/ /var/www/html/docroot/plugins/

EXPOSE ${PORT}
