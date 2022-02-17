zone "${forward_domain}" {
    type forward;
    forward only;
    forwarders { %{ for ip in nameservers ~}${ip};%{ endfor } };
};

zone "${reverse_domain}" {
    type forward;
    forward only;
    forwarders { %{ for ip in nameservers ~}${ip};%{ endfor } };
};