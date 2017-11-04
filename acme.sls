{% from 'states/nginx/map.jinja' import nginx as nginx_map with context %}
{% from 'states/defaults.map.jinja' import defaults with context %}

acme:
  pkg.installed:
    - name: {{ nginx_map.acme.package }}

  user.present:
    - name: {{ nginx_map.acme.user }}
    - home: {{ nginx_map.acme.home }}
    - createhome: True
    - gid_from_name: True
    - shell: {{ defaults.nologin }}
    - groups:
      - nginx
    - require:
      - pkg: nginx
