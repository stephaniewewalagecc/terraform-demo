#cloud-config
package_update: true
package_upgrade: true
package_reboot_if_required: true
packages:
  - docker-ce
  - docker-ce-cli
  - containerd.io
runcmd:
  - docker run --name db -d -e MYSQL_DATABASE=wp -e MYSQL_ROOT_PASSWORD=stas mysql
  - docker run --name web --link db:db -d -p 80:80 wordpress
apt:
  primary:
    - arches:
      - default
      uri: http://nz.archive.ubuntu.com/ubuntu
  security:
    - arches:
      - default
      uri: http://security.ubuntu.com/ubuntu
  sources:
    docker:
      source: deb https://download.docker.com/linux/ubuntu $RELEASE stable
      keyid: 9dc858229fc7dd38854ae2d88d81803c0ebfcd88

