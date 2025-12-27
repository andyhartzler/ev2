# Mautic 6 for Railway
FROM mautic/mautic:6-apache

LABEL maintainer="MO Young Democrats"

# Fix Apache MPM conflict - disable all MPMs except prefork
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork 2>/dev/null || true

# PHP Configuration
ENV PHP_INI_VALUE_MEMORY_LIMIT=512M
ENV PHP_INI_VALUE_UPLOAD_MAX_FILESIZE=64M
ENV PHP_INI_VALUE_POST_MAX_SIZE=64M
ENV PHP_INI_VALUE_MAX_EXECUTION_TIME=300
ENV PHP_INI_VALUE_DATE_TIMEZONE=America/Chicago

# Mautic Configuration
ENV DOCKER_MAUTIC_ROLE=mautic_web
ENV MAUTIC_RUN_CRON_JOBS=true

# Queue settings
ENV MAUTIC_MESSENGER_DSN_EMAIL=doctrine://default
ENV MAUTIC_MESSENGER_DSN_HIT=doctrine://default
ENV MAUTIC_MESSENGER_DSN_FAILED=doctrine://default

# Copy custom themes and plugins (if they exist)
COPY --chown=www-data:www-data themes/ /var/www/html/docroot/themes/
COPY --chown=www-data:www-data plugins/ /var/www/html/docroot/plugins/

EXPOSE 80
