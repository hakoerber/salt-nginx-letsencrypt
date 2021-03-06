#!stateconf
{% from 'states/nagios/map.jinja' import nagios as nagios_map with context %}
{% from 'states/defaults.map.jinja' import defaults with context %}

.params:
    stateconf.set: []
# --- end of state config ---

{% if params.proxy == true %}
nginx-selinux-bool-httpd-can-network-connect:
  selinux.boolean:
    - name: httpd_can_network_connect
    - value: 1
    - persist: True
    - require_in:
      - service: nginx
{% endif %}
