FROM mautic/mautic:latest

# Fix Apache MPM conflict at runtime (Railway/Heroku may inject configs)
# This wrapper script removes conflicting MPM modules before Apache starts
COPY fix-apache-mpm.sh /fix-apache-mpm.sh
RUN chmod +x /fix-apache-mpm.sh

# Override entrypoint to fix MPM before calling original entrypoint
ENTRYPOINT ["/fix-apache-mpm.sh"]

# Set timezone (can be overridden by runtime env var)
ENV PHP_INI_DATE_TIMEZONE='UTC'

# NOTE: Do NOT set database/admin credentials here!
# The mautic image reads these from environment variables at RUNTIME.
# Set these in Railway's environment variables settings:
#   - MAUTIC_DB_HOST
#   - MAUTIC_DB_PORT
#   - MAUTIC_DB_USER
#   - MAUTIC_DB_PASSWORD
#   - MAUTIC_DB_NAME
#   - MAUTIC_TRUSTED_PROXIES (set to '*' for Railway)
#   - MAUTIC_URL (your Railway app URL)
#   - MAUTIC_ADMIN_EMAIL
#   - MAUTIC_ADMIN_PASSWORD
