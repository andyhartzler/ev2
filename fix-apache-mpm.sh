#!/bin/bash
# Fix Apache MPM conflict at runtime
# This script ensures only one MPM module is loaded before starting Apache

# Remove any MPM symlinks that might have been injected at runtime
rm -f /etc/apache2/mods-enabled/mpm_event.load 2>/dev/null
rm -f /etc/apache2/mods-enabled/mpm_event.conf 2>/dev/null
rm -f /etc/apache2/mods-enabled/mpm_worker.load 2>/dev/null
rm -f /etc/apache2/mods-enabled/mpm_worker.conf 2>/dev/null

# Ensure mpm_prefork is enabled (required for mod_php)
if [ ! -f /etc/apache2/mods-enabled/mpm_prefork.load ]; then
    ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load 2>/dev/null || true
fi
if [ ! -f /etc/apache2/mods-enabled/mpm_prefork.conf ]; then
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf 2>/dev/null || true
fi

# Call the original entrypoint with all arguments
exec /docker-entrypoint.sh "$@"
