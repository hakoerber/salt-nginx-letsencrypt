#!stateconf
{% from 'states/nginx/map.jinja' import nginx as nginx_map with context %}
{% from 'states/defaults.map.jinja' import defaults with context %}

.params:
    stateconf.set: []
# --- end of state config ---

letsencrypt-webroot:
  file.directory:
    - name: {{ nginx_map.acme.webroot }}
    - user: {{ nginx_map.acme.user }}
    - group: nginx
    - require:
      - user: acme

letsencrypt-private-key:
  file.managed:
    - name: {{ nginx_map.acme.home }}/account.key
    - user: {{ nginx_map.acme.user }}
    - group: {{ nginx_map.acme.user }}
    - contents_pillar: acme:account_key
    - mode: '0400'
    - require:
      - user: acme

script-getcert:
  file.managed:
    - name: {{ nginx_map.acme.home }}/getcert
    - user: {{ nginx_map.acme.user }}
    - group: {{ nginx_map.acme.user }}
    - source: salt://states/nginx/files/getcert
    - mode: '0700'
    - require:
      - user: acme
      - file: letsencrypt-webroot

acme-nginx-reload-sudoers-entry:
  file.managed:
    - name: /etc/sudoers.d/acme-nginx-reload
    - user: root
    - group: root
    - source: salt://states/nginx/files/acme-nginx-reload-sudoers
    - mode: '600'

nginx-reload-script:
  file.managed:
    - name: /usr/local/bin/reload-nginx
    - user: root
    - group: root
    - source: salt://states/nginx/files/reload-nginx
    - mode: '755'

{% for domain in params.domains %}
letsencrypt-keydir-{{ domain.name }}:
  file.directory:
    - name: {{ nginx_map.acme.home }}/{{ domain.name }}
    - user: {{ nginx_map.acme.user }}
    - group: {{ nginx_map.acme.user }}
    - mode: '0750'
    - require:
      - user: acme

letsencrypt-key-{{ domain.name }}:
  cmd.run:
    - name: openssl genrsa 4096 > {{ nginx_map.acme.home }}/{{ domain.name }}/domain.key
    - runas: {{ nginx_map.acme.user }}
    - creates: {{ nginx_map.acme.home }}/{{ domain.name }}/domain.key
    - require:
      - file: letsencrypt-keydir-{{ domain.name }}

script-getcert-for-domain-{{ domain.name }}:
  file.managed:
    - name: {{ nginx_map.acme.home }}/getcert-{{ domain.name }}
    - user: {{ nginx_map.acme.user }}
    - group: {{ nginx_map.acme.user }}
    - source: salt://states/nginx/files/getcert.j2
    - template: jinja
    - mode: '0700'
    - defaults:
        domain: {{ domain }}
    - require:
      - user: acme
      - cmd: letsencrypt-key-{{ domain.name }}
      - file: script-getcert

getcert-for-domain-{{ domain.name }}:
  cmd.run:
    - name: {{ nginx_map.acme.home }}/getcert-{{ domain.name }}
    - runas: {{ nginx_map.acme.user }}
    - creates: {{ nginx_map.acme.home }}/{{ domain.name }}/domain.crt
    - require:
      - file: script-getcert-for-domain-{{ domain.name }}
      - file: nginx-reload-script
    - watch_in:
      - service: nginx


renew-cronjob-for-domain-{{ domain.name }}:
  cron.present:
    - name: {{ nginx_map.acme.home }}/getcert-{{ domain.name }}
    - identifier: renew-domain-{{ domain.name }}
    - user: acme
    - minute: random
    - hour: random
    - daymonth: 1
    - month: '*'
{% endfor %}
