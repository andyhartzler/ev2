# Mautic 6 for Railway deployment
FROM mautic/mautic:6-apache

# Railway provides PORT environment variable
ENV APACHE_PORT=${PORT:-80}

# Configure Apache to listen on Railway's PORT
RUN sed -i 's/Listen 80/Listen ${APACHE_PORT}/g' /etc/apache2/ports.conf && \
    sed -i 's/:80/:${APACHE_PORT}/g' /etc/apache2/sites-available/000-default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${APACHE_PORT}/ || exit 1

EXPOSE ${PORT:-80}
