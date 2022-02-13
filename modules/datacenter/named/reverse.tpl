$TTL    604800
@       IN      SOA     ${forward_domain}.  admin.${forward_domain}. (
                3           ; Serial
                604800      ; Refresh
                86400       ; Retry
                2419200     ; Expire
                604800 )    ; Negative Cache TTL

; name servers
%{ for hostname, ip in nameservers ~}
        IN      NS      ${hostname}.${forward_domain}.
%{ endfor ~}

; PTR records
%{ for hostname, ip in nameservers ~}
${join(".", reverse(slice(split(".", ip), 2, 4)))}     IN      PTR     ${hostname}.${forward_domain}.
%{ endfor ~}

%{ for hostname, ip in hosts ~}
${join(".", reverse(slice(split(".", ip), 2, 4)))}     IN      PTR     ${hostname}.${forward_domain}.
%{ endfor ~}