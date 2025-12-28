FROM mautic/mautic:latest

# Fix Apache MPM conflict - forcefully remove all MPM modules and enable only prefork
RUN rm -f /etc/apache2/mods-enabled/mpm_* && \
    ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load && \
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf && \
    apache2ctl configtest

# Set required environment variables
ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV DOCKER_MAUTIC_ROLE=mautic_web
