search ${forward_domain}
%{ for ip in values(nameservers) ~}
nameserver ${ip}
%{ endfor ~}