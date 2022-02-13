$TTL    604800
@       IN      SOA      ${keys(nameservers)[0]}.${forward_domain}.   admin.${forward_domain}. (
                    3               ; Serial
                    604800          ; Refresh
                    86400           ; Retry
                    2419200         ; Expire
                    604800 )        ; Negative Cache TTL

; name servers - NS records
%{ for hostname, ip in nameservers ~}
    IN      NS      ${hostname}.${forward_domain}.
%{ endfor ~}

; name servers - A records
%{ for hostname, ip in nameservers ~}
${hostname}.${forward_domain}.    IN      A       ${ip}
%{ endfor ~}

; hosts - A records
%{ for hostname, ip in hosts ~}
${hostname}.${forward_domain}.      IN      A       ${ip}
%{ endfor ~}
