# Required Azure NSG Inbound Rules

| Priority | Name    | Port | Protocol | Source | Action |
|----------|---------|------|----------|--------|--------|
| 300      | SSH     | 22   | TCP      | Any    | Allow  |
| 310      | HTTP    | 80   | TCP      | Any    | Allow  |
| 320      | HTTPS   | 443  | TCP      | Any    | Allow  |

Port 80 is required for Certbot's standalone challenge when issuing the Let's Encrypt cert.
Port 443 is the actual tunnel.
Port 22 is SSH for server management.

Note: The default DenyAllInBound rule at priority 65500 blocks everything else.
