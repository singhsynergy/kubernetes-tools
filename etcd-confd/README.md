# Setup etcd confd with Hashicorp Vault kv2: Quick and Easy

## prerequisites
- [Hashicorp Vault](https://github.com/singhsynergy/Devops-tools/tree/main/hashicorp-vault/hashicorp-vault-on-k8s)

## create and enable new secret engine with kv version2
```
vault secrets enable  -path=kv kv-v2
```
> Where kv is secret engine and kv-v2 is kv version

## create new secret and key-value
```
vault kv put -mount=kv database url=mysql.com
```
> Where kv is secret engine, database is secret, url is key and mysql.com is value.

## Establish the confdir directory.
The confdir is the location where template resource configurations and source templates are stored.
```
sudo mkdir -p /etc/confd/{conf.d,templates}
```

## Generate a configuration file for template resources, which are specified in TOML format within the confdir.

/etc/confd/conf.d/myconfig.conf.toml
```
[template]
src = "myconfig.conf.tmpl"
dest = "/root/myconfig.conf"
prefix = "/kv/data"
keys = [
    "database"
]
owner = "jenkins"
mode = "0644"
```

## Generate the source template, which consists of Golang text templates.

/etc/confd/templates/myconfig.conf.tmpl
```
[myconfig]
url = {{ getv "/database/data/url" }}
```

## Install Confd

You can install confd by referring to the [official guide](https://github.com/kelseyhightower/confd/blob/master/docs/installation.md), which corresponds to your specific operating system.

## Vault initialization

Initiating vault command to replace the Key-Value

```
confd -confdir /etc/confd -onetime -backend vault -node https://example.com -client-ca-keys ca_cert.pem -client-cert cert.pem  -client-key key.pem -auth-type token -auth-token <Root_Token>
```
Note: Substitute the domain, certificate files, and Token based on your specific environment.

The response should look similar to this:

```
2023-12-06T05:15:40Z jenkins-vm /usr/local/bin/confd[1781543]: INFO Backend set to vault
2023-12-06T05:15:40Z jenkins-vm /usr/local/bin/confd[1781543]: INFO Starting confd
2023-12-06T05:15:40Z jenkins-vm /usr/local/bin/confd[1781543]: INFO Backend source(s) set to https://example.com
2023-12-06T05:15:40Z jenkins-vm /usr/local/bin/confd[1781543]: INFO Vault authentication backend set to token
2023-12-06T05:15:41Z jenkins-vm /usr/local/bin/confd[1781543]: INFO /root/myconfig.conf has md5sum 4bf854d1233d37d3e524e4a06d7bca68 should be 5ab14215793cf14c1507d99905eac784
2023-12-06T05:15:41Z jenkins-vm /usr/local/bin/confd[1781543]: INFO Target config /root/myconfig.conf out of sync
2023-12-06T05:15:41Z jenkins-vm /usr/local/bin/confd[1781543]: DEBUG Overwriting target config /root/myconfig.conf
2023-12-06T05:15:41Z jenkins-vm /usr/local/bin/confd[1781543]: INFO Target config /root/myconfig.conf has been updated
The dest configuration file should now be in sync.
```
Check the content of the file after replacement of key-value.
```
cat /root/myconfig.conf
```
The response should look similar to this:
```
[myconfig]
url = mysql.com
```
