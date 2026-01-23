#!/bin/bash
# -----------------------------------------------------------
# Setup script to install a custom route and systemd service
# -----------------------------------------------------------

set -e

ROUTE_SCRIPT="/usr/local/bin/custom-routes.sh"
SERVICE_FILE="/etc/systemd/system/custom-routes.service"

echo "[INFO] Creating route script at $ROUTE_SCRIPT ..."
cat > "$ROUTE_SCRIPT" <<'EOF'
#!/bin/bash
ip route replace 10.1.8.0/24 via 10.7.230.2
EOF

chmod +x "$ROUTE_SCRIPT"
chown root:root "$ROUTE_SCRIPT"

echo "[INFO] Creating systemd service at $SERVICE_FILE ..."
cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=Add Custom Routes at Boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/custom-routes.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"
chown root:root "$SERVICE_FILE"

echo "[INFO] Reloading systemd and enabling service ..."
systemctl daemon-reload
systemctl enable custom-routes.service
systemctl restart custom-routes.service

echo "[SUCCESS] Custom route service deployed and started."
systemctl status custom-routes.service --no-pager
