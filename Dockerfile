FROM mautic/mautic:latest

# ============================================
# APACHE MPM FIX & AUTO-INSTALL ENTRYPOINT
# ============================================
COPY fix-apache-mpm.sh /fix-apache-mpm.sh
RUN chmod +x /fix-apache-mpm.sh
ENTRYPOINT ["/fix-apache-mpm.sh"]

# Set timezone
ENV PHP_INI_DATE_TIMEZONE='UTC'

# ============================================
# WHITELABELING - Missouri Young Democrats
# CSS-based approach (works with Mautic 5/6)
# ============================================

# Copy custom logos and CSS
COPY moyd-logo.png /var/www/html/media/images/moyd-logo.png
COPY favicon.png /var/www/html/media/images/favicon.png
COPY favicon.png /var/www/html/docroot/favicon.ico
COPY moyd-branding.css /var/www/html/media/css/moyd-branding.css

# Inject our custom CSS into Mautic's head template
# Also regenerate assets to apply changes
RUN set -ex && \
    # Find and inject CSS into head templates (both Twig and PHP)
    # Twig templates
    find /var/www/html -name "head*.twig" -type f 2>/dev/null | while read f; do \
        if ! grep -q "moyd-branding.css" "$f" 2>/dev/null; then \
            sed -i 's|</head>|<link rel="stylesheet" href="/media/css/moyd-branding.css" />\n</head>|g' "$f" 2>/dev/null || true; \
        fi; \
    done && \
    # PHP templates
    find /var/www/html -name "head*.php" -type f 2>/dev/null | while read f; do \
        if ! grep -q "moyd-branding.css" "$f" 2>/dev/null; then \
            sed -i 's|</head>|<link rel="stylesheet" href="/media/css/moyd-branding.css" />\n</head>|g' "$f" 2>/dev/null || true; \
        fi; \
    done && \
    # Also inject into base templates
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
    # Fix permissions
    chown -R www-data:www-data /var/www/html

# ============================================
# ENVIRONMENT VARIABLES
# Set these in Railway:
#   - MAUTIC_DB_HOST (required)
#   - MAUTIC_DB_PORT (default: 3306)
#   - MAUTIC_DB_USER (required)
#   - MAUTIC_DB_PASSWORD (required)
#   - MAUTIC_DB_NAME (required)
#   - MAUTIC_URL (required for auto-install, e.g., https://ev2-production.up.railway.app)
#   - MAUTIC_ADMIN_PASSWORD (required for auto-install)
#   - MAUTIC_TRUSTED_PROXIES (set to '*' for Railway)
# ============================================
