include:
  - elastic-repo

# SELinux has to be disabled for logstash to install correctly.
disable-selinux-live:
  cmd.run:
    - name: 'setenforce 0'
    - unless:
      - 'getenforce | grep Permissive'
      
# SELinux disabled permanently so logstash can come back up on reboot.
/etc/selinux/config:
  file.line:
    - content: "SELINUX=Permissive"
    - match: "SELINUX=Enforcing"
    - mode: "replace"

# Logstash requires a Java-8 JRE.
openjdk-1-8:
  pkg.installed:
    - name: java-1.8.0-openjdk.x86_64

# Installs logstash
logstash-pkg:
  pkg.installed:
    - name: logstash
    - require:
      - sls: elastic-repo

# Adds configuration to pre-parse log files and ship to elastic.
/etc/logstash/conf.d/bw-xsp.conf:
  file.managed:
    - source: salt://logstash/files/bw-xsp.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600
    - require:
      - pkg: logstash

# Reconfigures the logstash configuration to point to our elastic cloud instance.
/etc/logstash/logstash.yml:
  file.managed:
    - source: salt://logstash/files/logstash.yml.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600
    - require:
      - pkg: logstash

# Starts logstash and makes it persistent after reboots.
logstash-agent-service:
  service:
    - name: logstash
    - running
    - enable: True
    - require:
      - file: /etc/logstash/logstash.yml
    - watch:
      - file: /etc/logstash/logstash.yml

