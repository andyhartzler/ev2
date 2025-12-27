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
# Manual approach (more reliable than whitelabeler tool)
# ============================================

# Copy custom logos
COPY moyd-logo.png /var/www/html/media/images/moyd-logo.png
COPY favicon.png /var/www/html/media/images/favicon.png
COPY favicon.png /var/www/html/favicon.png
COPY favicon.png /var/www/html/docroot/favicon.ico

# Apply branding changes
RUN set -ex && \
    # ----------------------------------------
    # 1. Replace sidebar logo (SVG -> IMG tag)
    # ----------------------------------------
    SIDEBAR_FILE="/var/www/html/app/bundles/CoreBundle/Views/LeftPanel/index.html.php" && \
    if [ -f "$SIDEBAR_FILE" ]; then \
        # Replace the mautic-brand-logo SVG with our image
        sed -i 's|<svg class="mautic-brand-logo"[^>]*>.*</svg>|<img src="/media/images/moyd-logo.png" alt="MOYD" style="width:100%; max-width:160px; margin:10px auto; display:block;"/>|g' "$SIDEBAR_FILE" 2>/dev/null || true; \
    fi && \
    # ----------------------------------------
    # 2. Replace login page logo
    # ----------------------------------------
    LOGIN_FILE="/var/www/html/app/bundles/UserBundle/Views/Security/base.html.php" && \
    if [ -f "$LOGIN_FILE" ]; then \
        sed -i 's|<svg class="mautic-logo-figure"[^>]*>.*</svg>|<img src="/media/images/moyd-logo.png" alt="MOYD Mail" style="width:250px; margin:20px auto; display:block;"/>|g' "$LOGIN_FILE" 2>/dev/null || true; \
    fi && \
    # ----------------------------------------
    # 3. Update page title / company name in HEAD
    # ----------------------------------------
    HEAD_FILE="/var/www/html/app/bundles/CoreBundle/Views/Default/head.html.php" && \
    if [ -f "$HEAD_FILE" ]; then \
        sed -i "s/'Mautic'/'MOYD Mail'/g" "$HEAD_FILE" 2>/dev/null || true; \
    fi && \
    # ----------------------------------------
    # 4. Update footer company name
    # ----------------------------------------
    BASE_FILE="/var/www/html/app/bundles/CoreBundle/Views/Default/base.html.php" && \
    if [ -f "$BASE_FILE" ]; then \
        sed -i "s/Mautic, Inc. All Rights Reserved/Missouri Young Democrats/g" "$BASE_FILE" 2>/dev/null || true; \
        sed -i "s/Mautic/MOYD Mail/g" "$BASE_FILE" 2>/dev/null || true; \
    fi && \
    # ----------------------------------------
    # 5. Update colors in CSS (Navy blue #273351)
    # ----------------------------------------
    CSS_APP="/var/www/html/app/bundles/CoreBundle/Assets/css/app.css" && \
    if [ -f "$CSS_APP" ]; then \
        # Replace Mautic purple/blue with our navy
        sed -i 's/#4e5e9e/#273351/gi' "$CSS_APP" 2>/dev/null || true; \
        sed -i 's/#4a4e68/#273351/gi' "$CSS_APP" 2>/dev/null || true; \
        sed -i 's/#35363e/#273351/gi' "$CSS_APP" 2>/dev/null || true; \
    fi && \
    # Also update the compiled media CSS
    MEDIA_CSS="/var/www/html/media/css/app.css" && \
    if [ -f "$MEDIA_CSS" ]; then \
        sed -i 's/#4e5e9e/#273351/gi' "$MEDIA_CSS" 2>/dev/null || true; \
        sed -i 's/#4a4e68/#273351/gi' "$MEDIA_CSS" 2>/dev/null || true; \
        sed -i 's/#35363e/#273351/gi' "$MEDIA_CSS" 2>/dev/null || true; \
    fi && \
    # ----------------------------------------
    # 6. Update JS title references
    # ----------------------------------------
    JS_CONTENT="/var/www/html/app/bundles/CoreBundle/Assets/js/1a.content.js" && \
    if [ -f "$JS_CONTENT" ]; then \
        sed -i 's/"Mautic"/"MOYD Mail"/g' "$JS_CONTENT" 2>/dev/null || true; \
    fi && \
    MEDIA_JS="/var/www/html/media/js/app.js" && \
    if [ -f "$MEDIA_JS" ]; then \
        sed -i 's/"Mautic"/"MOYD Mail"/g' "$MEDIA_JS" 2>/dev/null || true; \
    fi && \
    # ----------------------------------------
    # 7. Fix permissions
    # ----------------------------------------
    chown -R www-data:www-data /var/www/html

# ============================================
# ENVIRONMENT VARIABLES
# Set these in Railway:
#   - MAUTIC_DB_HOST
#   - MAUTIC_DB_PORT (default: 3306)
#   - MAUTIC_DB_USER
#   - MAUTIC_DB_PASSWORD
#   - MAUTIC_DB_NAME
#   - MAUTIC_URL (your Railway app URL, e.g., https://ev2-production.up.railway.app)
#   - MAUTIC_ADMIN_EMAIL (default: andrew@moyoungdemocrats.org)
#   - MAUTIC_ADMIN_PASSWORD (required)
#   - MAUTIC_TRUSTED_PROXIES (set to '*' for Railway)
# ============================================
