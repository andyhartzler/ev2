#!/bin/bash
# Enhanced entrypoint for MOYD Mautic
# - Fixes Apache MPM conflict
# - Auto-installs Mautic on first run

echo "[MOYD] Starting enhanced entrypoint..."

# ========================================
# 1. Fix Apache MPM conflict at runtime
# ========================================
echo "[MOYD] Fixing Apache MPM configuration..."
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
echo "[MOYD] Apache MPM fix applied."

# ========================================
# 2. Auto-install Mautic if not installed
# ========================================
echo "[MOYD] Checking if auto-install is needed..."
echo "[MOYD] MAUTIC_URL=${MAUTIC_URL:-not set}"
echo "[MOYD] MAUTIC_DB_HOST=${MAUTIC_DB_HOST:-not set}"
echo "[MOYD] MAUTIC_ADMIN_PASSWORD is ${MAUTIC_ADMIN_PASSWORD:+set}${MAUTIC_ADMIN_PASSWORD:-not set}"

# Check if Mautic is already installed
NEEDS_INSTALL=false
if [ -f /var/www/html/config/local.php ]; then
    if grep -q "'site_url'" /var/www/html/config/local.php 2>/dev/null; then
        echo "[MOYD] Mautic already installed (found site_url in local.php), skipping auto-install."
    else
        echo "[MOYD] local.php exists but no site_url found, needs installation."
        NEEDS_INSTALL=true
    fi
else
    echo "[MOYD] No local.php found, needs installation."
    NEEDS_INSTALL=true
fi

# Only proceed if we have required env vars
if [ "$NEEDS_INSTALL" = true ]; then
    if [ -z "$MAUTIC_URL" ]; then
        echo "[MOYD] WARNING: MAUTIC_URL not set, skipping auto-install."
        echo "[MOYD] Set MAUTIC_URL in Railway to enable auto-install."
    elif [ -z "$MAUTIC_ADMIN_PASSWORD" ]; then
        echo "[MOYD] WARNING: MAUTIC_ADMIN_PASSWORD not set, skipping auto-install."
        echo "[MOYD] Set MAUTIC_ADMIN_PASSWORD in Railway to enable auto-install."
    elif [ -z "$MAUTIC_DB_HOST" ]; then
        echo "[MOYD] WARNING: MAUTIC_DB_HOST not set, skipping auto-install."
    else
        echo "[MOYD] All required env vars set, will attempt auto-install after MySQL is ready..."

        # Wait for MySQL (the original entrypoint also does this, but we need it first)
        echo "[MOYD] Waiting for MySQL at ${MAUTIC_DB_HOST}:${MAUTIC_DB_PORT:-3306}..."
        MAX_TRIES=60
        TRIES=0
        while [ $TRIES -lt $MAX_TRIES ]; do
            if php -r "try { new PDO('mysql:host=${MAUTIC_DB_HOST};port=${MAUTIC_DB_PORT:-3306}', '${MAUTIC_DB_USER}', '${MAUTIC_DB_PASSWORD}'); echo 'OK'; } catch(Exception \$e) { exit(1); }" 2>/dev/null | grep -q "OK"; then
                echo "[MOYD] MySQL is ready!"
                break
            fi
            echo "[MOYD] MySQL not ready (attempt $TRIES/$MAX_TRIES), waiting..."
            sleep 2
            TRIES=$((TRIES + 1))
        done

        if [ $TRIES -lt $MAX_TRIES ]; then
            echo "[MOYD] Running automatic Mautic installation..."
            cd /var/www/html

            # Run mautic:install
            php bin/console mautic:install "$MAUTIC_URL" \
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
                --no-interaction 2>&1

            if [ $? -eq 0 ]; then
                echo "[MOYD] Mautic installation completed successfully!"
                # Clear cache after install
                php bin/console cache:clear 2>/dev/null || true
            else
                echo "[MOYD] Mautic installation failed. Check the logs above for errors."
            fi
        else
            echo "[MOYD] MySQL connection timed out after $MAX_TRIES attempts."
        fi
    fi
fi

# ========================================
# 3. Call the original mautic entrypoint
# ========================================
echo "[MOYD] Calling original Mautic entrypoint..."
exec /entrypoint.sh "$@"
