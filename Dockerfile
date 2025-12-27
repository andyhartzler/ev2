# Mautic 6 for Railway
FROM mautic/mautic:6-apache

LABEL maintainer="MO Young Democrats"

# Fix Apache MPM conflict - forcefully remove all MPM symlinks and keep only prefork
RUN rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf && \
    ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load && \
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf && \
    apache2ctl configtest

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
