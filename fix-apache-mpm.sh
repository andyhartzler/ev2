#!/bin/bash
# Fix Apache MPM conflict at container startup time
# This must run BEFORE Apache starts to prevent "More than one MPM loaded" error

# Remove all MPM modules from enabled list
rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf 2>/dev/null

# Enable only mpm_prefork (required for mod_php)
ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load
if [ -f /etc/apache2/mods-available/mpm_prefork.conf ]; then
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf
fi

# Execute the original entrypoint
exec /entrypoint.sh "$@"
