FROM mautic/mautic:latest

# Fix Apache MPM conflict - use prefork only
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true && \
    a2enmod mpm_prefork 2>/dev/null || true

# Set required environment variables
ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV DOCKER_MAUTIC_ROLE=mautic_web
