#!/bin/bash
# Enhanced entrypoint for MOYD Mautic
# - Fixes Apache MPM conflict
# - Auto-installs Mautic on first run

# ========================================
# 1. Fix Apache MPM conflict at runtime
# ========================================
rm -f /etc/apache2/mods-enabled/mpm_event.load 2>/dev/null
rm -f /etc/apache2/mods-enabled/mpm_event.conf 2>/dev/null
rm -f /etc/apache2/mods-enabled/mpm_worker.load 2>/dev/null
rm -f /etc/apache2/mods-enabled/mpm_worker.conf 2>/dev/null

if [ ! -f /etc/apache2/mods-enabled/mpm_prefork.load ]; then
    ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load 2>/dev/null || true
fi
if [ ! -f /etc/apache2/mods-enabled/mpm_prefork.conf ]; then
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf 2>/dev/null || true
fi

# ========================================
# 2. Auto-install Mautic if not installed
# ========================================
# Check if Mautic is already installed by looking for site_url in local.php
if [ -f /var/www/html/config/local.php ]; then
    if grep -q "site_url" /var/www/html/config/local.php 2>/dev/null; then
        echo "[MOYD] Mautic already installed, skipping auto-install."
    else
        NEEDS_INSTALL=true
    fi
else
    NEEDS_INSTALL=true
fi

if [ "$NEEDS_INSTALL" = true ] && [ -n "$MAUTIC_URL" ]; then
    echo "[MOYD] Waiting for MySQL to be ready..."

    # Wait for MySQL
    MAX_TRIES=30
    TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        if php -r "new PDO('mysql:host=${MAUTIC_DB_HOST};port=${MAUTIC_DB_PORT:-3306}', '${MAUTIC_DB_USER}', '${MAUTIC_DB_PASSWORD}');" 2>/dev/null; then
            echo "[MOYD] MySQL is ready!"
            break
        fi
        echo "[MOYD] MySQL not ready, waiting..."
        sleep 2
        TRIES=$((TRIES + 1))
    done

    if [ $TRIES -lt $MAX_TRIES ]; then
        echo "[MOYD] Running automatic Mautic installation..."

        cd /var/www/html

        # Run mautic:install with all parameters
        sudo -u www-data php bin/console mautic:install "$MAUTIC_URL" \
            --db_host="${MAUTIC_DB_HOST}" \
            --db_port="${MAUTIC_DB_PORT:-3306}" \
            --db_name="${MAUTIC_DB_NAME}" \
            --db_user="${MAUTIC_DB_USER}" \
            --db_password="${MAUTIC_DB_PASSWORD}" \
            --admin_email="${MAUTIC_ADMIN_EMAIL:-andrew@moyoungdemocrats.org}" \
            --admin_password="${MAUTIC_ADMIN_PASSWORD}" \
            --admin_firstname="${MAUTIC_ADMIN_FIRSTNAME:-Andrew}" \
            --admin_lastname="${MAUTIC_ADMIN_LASTNAME:-Hartzler}" \
            --admin_username="${MAUTIC_ADMIN_USERNAME:-admin}" \
            --mailer_from_name="${MAUTIC_MAILER_FROM_NAME:-Missouri Young Democrats}" \
            --mailer_from_email="${MAUTIC_ADMIN_EMAIL:-andrew@moyoungdemocrats.org}" \
            --no-interaction

        if [ $? -eq 0 ]; then
            echo "[MOYD] Mautic installation completed successfully!"
        else
            echo "[MOYD] Mautic installation failed, will try again on next restart."
        fi
    else
        echo "[MOYD] MySQL connection timed out, skipping auto-install."
    fi
fi

# ========================================
# 3. Call the original mautic entrypoint
# ========================================
exec /entrypoint.sh "$@"
