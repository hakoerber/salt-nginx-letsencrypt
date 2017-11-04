#!stateconf
{% from 'states/nginx/map.jinja' import nginx as nginx_map with context %}
{% from 'states/defaults.map.jinja' import defaults with context %}

.params:
    stateconf.set: []
# --- end of state config ---

{% for vhost in params.vhosts %}
nginx-vhost-{{ vhost.name }}.conf:
  file.managed:
    - name: {{ nginx_map.conf.include_dir ~ '/' ~ vhost.priority ~ '_vhost_' ~ vhost.name ~ '.conf' }}
    - user: root
    - group: {{ defaults.rootgroup }}
    - mode: 644
    - source: {{ 'salt://states/nginx/files/vhost.conf.jinja' }}
    - template: jinja
    - defaults:
        vhost: {{ vhost }}
    - require:
      - file: nginx-conf.d
    - watch_in:
      - service: nginx

{% if vhost.type == 'static' %}
vhost_{{ vhost.name }}:
  file.directory:
    - name: {{ vhost.path }}
    - user: {{ nginx_map.user }}
    - group: {{ nginx_map.group }}
    - makedirs: True
{% endif %}
{% endfor %}
