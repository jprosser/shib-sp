#!/usr/bin/env bats

load ../common

@test "Shibd binary available" {
  docker run -i ${imagename}_${tag} find /usr/sbin/shibd
  docker run -i ${imagename}_${tag}:arm64 find /usr/sbin/shibd
}

@test "Shibboleth root available" {
  docker run -i ${imagename}_${tag} find /etc/shibboleth
  docker run -i ${imagename}_${tag}:arm64 find /etc/shibboleth
}

@test "Sample attribute map available" {
  docker run -i ${imagename}_${tag} find /etc/shibboleth/attribute-map.xml
  docker run -i ${imagename}_${tag}:arm64 find /etc/shibboleth/attribute-map.xml
}

@test "Includes InCommon cert" {
  docker run -i ${imagename}_${tag} find /etc/shibboleth/inc-md-cert.pem
  docker run -i ${imagename}_${tag}:arm64 find /etc/shibboleth/inc-md-cert.pem
}

@test "Includes startup script" {
  docker run -i ${imagename}_${tag} find /usr/local/bin/startup.sh
  docker run -i ${imagename}_${tag}:arm64 find /usr/local/bin/startup.sh
}

