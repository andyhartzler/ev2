FROM mautic/mautic:latest

# ============================================
# FIX APACHE MPM CONFLICT AT BUILD TIME
# This MUST be done before Apache starts
# ============================================
RUN rm -f /etc/apache2/mods-enabled/mpm_event.load \
          /etc/apache2/mods-enabled/mpm_event.conf \
          /etc/apache2/mods-enabled/mpm_worker.load \
          /etc/apache2/mods-enabled/mpm_worker.conf && \
    ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load && \
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf

# Set timezone and role
ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV DOCKER_MAUTIC_ROLE=mautic_web

# ============================================
# WHITELABELING - Missouri Young Democrats
# ============================================

# Copy custom logos and CSS
COPY moyd-logo.png /var/www/html/media/images/moyd-logo.png
COPY favicon.png /var/www/html/media/images/favicon.png
COPY favicon.png /var/www/html/docroot/favicon.ico
COPY moyd-branding.css /var/www/html/media/css/moyd-branding.css

# Make sure CSS is accessible (fix permissions)
RUN chmod 644 /var/www/html/media/css/moyd-branding.css && \
    chown www-data:www-data /var/www/html/media/css/moyd-branding.css

# Inject our custom CSS into Mautic's templates
RUN set -ex && \
    # Find and inject CSS into head templates (both Twig and PHP)
    find /var/www/html -name "head*.twig" -type f 2>/dev/null | while read f; do \
        if ! grep -q "moyd-branding.css" "$f" 2>/dev/null; then \
            sed -i 's|</head>|<link rel="stylesheet" href="/media/css/moyd-branding.css" />\n</head>|g' "$f" 2>/dev/null || true; \
        fi; \
    done && \
    find /var/www/html -name "head*.php" -type f 2>/dev/null | while read f; do \
        if ! grep -q "moyd-branding.css" "$f" 2>/dev/null; then \
            sed -i 's|</head>|<link rel="stylesheet" href="/media/css/moyd-branding.css" />\n</head>|g' "$f" 2>/dev/null || true; \
        fi; \
    done && \
    find /var/www/html -name "base*.twig" -type f 2>/dev/null | while read f; do \
        if ! grep -q "moyd-branding.css" "$f" 2>/dev/null; then \
            sed -i 's|</head>|<link rel="stylesheet" href="/media/css/moyd-branding.css" />\n</head>|g' "$f" 2>/dev/null || true; \
        fi; \
    done && \
    find /var/www/html -name "base*.php" -type f 2>/dev/null | while read f; do \
        if ! grep -q "moyd-branding.css" "$f" 2>/dev/null; then \
            sed -i 's|</head>|<link rel="stylesheet" href="/media/css/moyd-branding.css" />\n</head>|g' "$f" 2>/dev/null || true; \
        fi; \
    done && \
    chown -R www-data:www-data /var/www/html

# ============================================
# ENVIRONMENT VARIABLES
# Set these in Railway:
#   - MAUTIC_DB_HOST (required)
#   - MAUTIC_DB_PORT (default: 3306)
#   - MAUTIC_DB_USER (required)
#   - MAUTIC_DB_PASSWORD (required)
#   - MAUTIC_DB_NAME (required)
#   - MAUTIC_URL (required for auto-install)
#   - MAUTIC_ADMIN_PASSWORD (required for auto-install, must be complex!)
#   - MAUTIC_TRUSTED_PROXIES (set to '*' for Railway)
# ============================================
