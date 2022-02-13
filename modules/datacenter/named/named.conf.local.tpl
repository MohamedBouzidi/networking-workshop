zone "${forward_domain}" {
    type master;
    file "/etc/named/zones/db.${forward_domain}";
};

zone "${reverse_domain}" {
    type master;
    file "/etc/named/zones/db.${reverse_domain_zone_name}";
};