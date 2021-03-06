#!stateconf
{% from 'states/nginx/map.jinja' import nginx as nginx_map with context %}
{% from 'states/defaults.map.jinja' import defaults with context %}

.params:
    stateconf.set: []
# --- end of state config ---

nginx.conf:
  file.managed:
    - name: {{ nginx_map.conf.main.path }}
    - user: root
    - group: {{ defaults.rootgroup }}
    - mode: 644
    - source: {{ nginx_map.conf.main.template }}
    - template: jinja
    - defaults:
        user: {{ params.get('user', nginx_map.user) }}
        group: {{ params.get('group', nginx_map.group) }}
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx

nginx-conf.d:
  file.directory:
    - name: {{ nginx_map.conf.include_dir }}
    - user: root
    - group: {{ defaults.rootgroup }}
    - mode: 755
    - require:
      - pkg: nginx
    - require_in:
      - file: nginx.conf

{% macro include_conf(name, include, context={}, include_states=[]) %}
{% set path = nginx_map.conf.include_dir + '/' + name + '.conf' %}
{% if include %}
nginx-{{ name }}.conf:
  file.managed:
    - name: {{ path }}
    - user: root
    - group: {{ defaults.rootgroup }}
    - mode: 644
    - source: {{ 'salt://states/nginx/files/' + name + '.conf.jinja' }}
    - template: jinja
    - defaults: {{ context }}
    - require:
      - file: nginx-conf.d
    - watch_in:
      - service: nginx

{% for state in include_states %}
include:
  - states.nginx.include.{{ state }}
{% endfor %}

{% else %}
nginx-{{ name }}.conf-absent:
  file.absent:
    - name: {{ path }}
    - watch_in:
      - service: nginx
{% endif %}
{% endmacro %}

{% set name = '10_resolver' %}
{% set include = params.get('resolver', none) is not none %}
{% set context = {'resolver': params.get('resolver')} %}
{{ include_conf(name, include, context) }}

{% set name = '10_force_https' %}
{% set include = params.get('force_https', False) %}
{% set context = {'ipv6': params.get('ipv6', False)} %}
{{ include_conf(name, include, context) }}

{% set name = '15_ssl' %}
{% set include =  params.get('https', False) %}
{% set context = {'simple': params.get('ssl', {}).get('simple', False)} %}
{{ include_conf(name, include, context) }}

{% set name = '20_acme_backend' %}
{% set include = params.get('acme_endpoint', false) == true %}
{% set context = {} %}
{{ include_conf(name, include, context) }}

{% set name = '30_local_status' %}
{% set include = params.get('local_status', True) %}
{{ include_conf(name, include) }}
