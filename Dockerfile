FROM mautic/mautic:latest

# Fix Apache MPM conflict at runtime (Railway/Heroku may inject configs)
# This wrapper script removes conflicting MPM modules before Apache starts
COPY fix-apache-mpm.sh /fix-apache-mpm.sh
RUN chmod +x /fix-apache-mpm.sh

# Override entrypoint to fix MPM before calling original entrypoint
ENTRYPOINT ["/fix-apache-mpm.sh"]

# Set timezone (can be overridden by runtime env var)
ENV PHP_INI_DATE_TIMEZONE='UTC'

# ============================================
# WHITELABELING - Missouri Young Democrats
# ============================================

# Copy custom logo and favicon
COPY moyd-logo.png /var/www/html/moyd-logo.png
COPY favicon.png /var/www/html/favicon.png

# Copy whitelabel config
COPY whitelabel-config.json /tmp/whitelabel-config.json

# Install git and clone mautic-whitelabeler, then apply branding
RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/nickian/mautic-whitelabeler.git /tmp/mautic-whitelabeler && \
    # Copy config to whitelabeler assets folder
    mkdir -p /tmp/mautic-whitelabeler/assets && \
    cp /tmp/whitelabel-config.json /tmp/mautic-whitelabeler/assets/config.json && \
    # Copy logos to whitelabeler assets for processing
    cp /var/www/html/moyd-logo.png /tmp/mautic-whitelabeler/assets/sidebar_logo.png && \
    cp /var/www/html/moyd-logo.png /tmp/mautic-whitelabeler/assets/login_logo.png && \
    cp /var/www/html/favicon.png /tmp/mautic-whitelabeler/assets/favicon.png && \
    # Run the whitelabeler
    cd /tmp/mautic-whitelabeler && php cli.php --whitelabel && \
    # Change site title to "MOYD Mail"
    find /var/www/html -name "*.php" -type f -exec sed -i 's/Mautic/MOYD Mail/g' {} + 2>/dev/null || true && \
    find /var/www/html -name "*.twig" -type f -exec sed -i 's/Mautic/MOYD Mail/g' {} + 2>/dev/null || true && \
    # Clean up
    apt-get remove -y git && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/mautic-whitelabeler /tmp/whitelabel-config.json && \
    # Fix ownership
    chown -R www-data:www-data /var/www/html

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
