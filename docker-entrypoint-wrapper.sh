#!/bin/bash
# ============================================
# MOYD Custom Entrypoint Wrapper for Mautic
# This script wraps the original Mautic entrypoint
# to add auto-install and custom configuration
# ============================================

echo "============================================"
echo "[MOYD] Custom Mautic Entrypoint Starting..."
echo "[MOYD] Timestamp: $(date)"
echo "============================================"

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
# 2. Handle environment variable mappings
# ========================================
echo "[MOYD] Setting up environment variables..."

# Handle alternate variable names (Railway uses different names)
export MAUTIC_URL="${MAUTIC_URL:-$MAUTIC_SITE_URL}"
export MAUTIC_DB_NAME="${MAUTIC_DB_NAME:-${MAUTIC_DB_DATABASE:-railway}}"
export MAUTIC_DB_HOST="${MAUTIC_DB_HOST:-${MYSQL_HOST:-${MYSQLHOST:-localhost}}}"
export MAUTIC_DB_PORT="${MAUTIC_DB_PORT:-${MYSQL_PORT:-${MYSQLPORT:-3306}}}"
export MAUTIC_DB_USER="${MAUTIC_DB_USER:-${MYSQL_USER:-${MYSQLUSER:-root}}}"
export MAUTIC_DB_PASSWORD="${MAUTIC_DB_PASSWORD:-${MYSQL_PASSWORD:-${MYSQLPASSWORD:-$MYSQL_ROOT_PASSWORD}}}"

# Set the Docker role for Mautic (required by official image)
export DOCKER_MAUTIC_ROLE="${DOCKER_MAUTIC_ROLE:-mautic_web}"

echo "[MOYD] Environment Configuration:"
echo "[MOYD]   MAUTIC_URL=${MAUTIC_URL:-NOT SET}"
echo "[MOYD]   MAUTIC_DB_HOST=${MAUTIC_DB_HOST:-NOT SET}"
echo "[MOYD]   MAUTIC_DB_PORT=${MAUTIC_DB_PORT}"
echo "[MOYD]   MAUTIC_DB_NAME=${MAUTIC_DB_NAME:-NOT SET}"
echo "[MOYD]   MAUTIC_DB_USER=${MAUTIC_DB_USER:-NOT SET}"
echo "[MOYD]   MAUTIC_DB_PASSWORD=$([ -n "$MAUTIC_DB_PASSWORD" ] && echo '[SET]' || echo 'NOT SET')"
echo "[MOYD]   MAUTIC_ADMIN_PASSWORD=$([ -n "$MAUTIC_ADMIN_PASSWORD" ] && echo '[SET]' || echo 'NOT SET')"
echo "[MOYD]   DOCKER_MAUTIC_ROLE=${DOCKER_MAUTIC_ROLE}"

# ========================================
# 3. Check if Mautic needs installation
# ========================================
echo "[MOYD] Checking if Mautic auto-install is needed..."

NEEDS_INSTALL=false
LOCAL_PHP="/var/www/html/config/local.php"

if [ -f "$LOCAL_PHP" ]; then
    if grep -q "'site_url'" "$LOCAL_PHP" 2>/dev/null; then
        echo "[MOYD] Mautic already installed (found site_url in local.php)"
    else
        echo "[MOYD] local.php exists but incomplete, needs installation"
        NEEDS_INSTALL=true
    fi
else
    echo "[MOYD] No local.php found, needs installation"
    NEEDS_INSTALL=true
fi

# ========================================
# 4. Auto-install Mautic if needed
# ========================================
if [ "$NEEDS_INSTALL" = true ]; then
    # Check required variables
    MISSING_VARS=""
    [ -z "$MAUTIC_URL" ] && MISSING_VARS="$MISSING_VARS MAUTIC_URL"
    [ -z "$MAUTIC_ADMIN_PASSWORD" ] && MISSING_VARS="$MISSING_VARS MAUTIC_ADMIN_PASSWORD"
    [ -z "$MAUTIC_DB_HOST" ] && MISSING_VARS="$MISSING_VARS MAUTIC_DB_HOST"
    [ -z "$MAUTIC_DB_USER" ] && MISSING_VARS="$MISSING_VARS MAUTIC_DB_USER"
    [ -z "$MAUTIC_DB_PASSWORD" ] && MISSING_VARS="$MISSING_VARS MAUTIC_DB_PASSWORD"

    if [ -n "$MISSING_VARS" ]; then
        echo "[MOYD] WARNING: Cannot auto-install, missing variables:$MISSING_VARS"
        echo "[MOYD] Skipping auto-install, will show web installer instead"
    else
        echo "[MOYD] All required variables set, attempting auto-install..."

        # Wait for MySQL to be ready
        echo "[MOYD] Waiting for MySQL at ${MAUTIC_DB_HOST}:${MAUTIC_DB_PORT}..."

        MAX_TRIES=30
        TRIES=0
        MYSQL_READY=false

        while [ $TRIES -lt $MAX_TRIES ]; do
            RESULT=$(php -r "
                try {
                    \$pdo = new PDO(
                        'mysql:host=${MAUTIC_DB_HOST};port=${MAUTIC_DB_PORT}',
                        '${MAUTIC_DB_USER}',
                        '${MAUTIC_DB_PASSWORD}'
                    );
                    echo 'OK';
                } catch(Exception \$e) {
                    echo 'ERROR: ' . \$e->getMessage();
                }
            " 2>&1)

            if echo "$RESULT" | grep -q "^OK"; then
                echo "[MOYD] MySQL is ready!"
                MYSQL_READY=true
                break
            fi

            TRIES=$((TRIES + 1))
            if [ $TRIES -eq 1 ] || [ $((TRIES % 10)) -eq 0 ]; then
                echo "[MOYD] MySQL attempt $TRIES/$MAX_TRIES: $RESULT"
            else
                echo "[MOYD] Waiting for MySQL (attempt $TRIES/$MAX_TRIES)..."
            fi
            sleep 2
        done

        if [ "$MYSQL_READY" = true ]; then
            echo "[MOYD] ============================================"
            echo "[MOYD] Running Mautic CLI Installation..."
            echo "[MOYD] ============================================"

            cd /var/www/html

            # Create the database if it doesn't exist
            echo "[MOYD] Ensuring database '${MAUTIC_DB_NAME}' exists..."
            php -r "
                try {
                    \$pdo = new PDO(
                        'mysql:host=${MAUTIC_DB_HOST};port=${MAUTIC_DB_PORT}',
                        '${MAUTIC_DB_USER}',
                        '${MAUTIC_DB_PASSWORD}'
                    );
                    \$pdo->exec('CREATE DATABASE IF NOT EXISTS \`${MAUTIC_DB_NAME}\`');
                    echo 'Database ready';
                } catch(Exception \$e) {
                    echo 'Database error: ' . \$e->getMessage();
                }
            " 2>&1

            # Run mautic:install as www-data user
            echo "[MOYD] Running mautic:install command..."

            INSTALL_OUTPUT=$(su -s /bin/bash www-data -c "php bin/console mautic:install '${MAUTIC_URL}' \
                --db_host='${MAUTIC_DB_HOST}' \
                --db_port='${MAUTIC_DB_PORT}' \
                --db_name='${MAUTIC_DB_NAME}' \
                --db_user='${MAUTIC_DB_USER}' \
                --db_password='${MAUTIC_DB_PASSWORD}' \
                --admin_email='${MAUTIC_ADMIN_EMAIL:-admin@example.com}' \
                --admin_password='${MAUTIC_ADMIN_PASSWORD}' \
                --admin_firstname='${MAUTIC_ADMIN_FIRSTNAME:-Admin}' \
                --admin_lastname='${MAUTIC_ADMIN_LASTNAME:-User}' \
                --admin_username='${MAUTIC_ADMIN_USERNAME:-admin}' \
                --mailer_from_name='${MAUTIC_MAILER_FROM_NAME:-Mautic}' \
                --mailer_from_email='${MAUTIC_ADMIN_EMAIL:-admin@example.com}' \
                --no-interaction 2>&1")

            INSTALL_EXIT_CODE=$?

            echo "[MOYD] Install output:"
            echo "$INSTALL_OUTPUT"

            if [ $INSTALL_EXIT_CODE -eq 0 ]; then
                echo "[MOYD] ============================================"
                echo "[MOYD] Mautic installation SUCCESSFUL!"
                echo "[MOYD] ============================================"

                # Clear cache
                echo "[MOYD] Clearing cache..."
                su -s /bin/bash www-data -c "php bin/console cache:clear" 2>/dev/null || true

                # Fix permissions
                chown -R www-data:www-data /var/www/html/config
                chown -R www-data:www-data /var/www/html/var
            else
                echo "[MOYD] ============================================"
                echo "[MOYD] Mautic installation FAILED (exit code: $INSTALL_EXIT_CODE)"
                echo "[MOYD] Will fall back to web installer"
                echo "[MOYD] ============================================"
            fi
        else
            echo "[MOYD] MySQL connection timed out after $MAX_TRIES attempts"
        fi
    fi
fi

# ========================================
# 5. Call the original Mautic entrypoint
# ========================================
echo "[MOYD] ============================================"
echo "[MOYD] Calling original Mautic entrypoint..."
echo "[MOYD] ============================================"

# Find and execute the original entrypoint
if [ -f /docker-entrypoint-original.sh ]; then
    echo "[MOYD] Using saved original entrypoint"
    exec /docker-entrypoint-original.sh "$@"
elif [ -f /entrypoint.sh ]; then
    echo "[MOYD] Using /entrypoint.sh"
    exec /entrypoint.sh "$@"
else
    echo "[MOYD] No original entrypoint found, starting Apache directly"
    exec apache2-foreground
fi
