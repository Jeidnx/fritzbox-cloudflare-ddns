fritzbox-cloudflare-ddns
=======

Dynamic DNS with FritzBox and Cloudflare

Easy solution to setup a **local** Dynamic DNS Server if you are running a Fritzbox and using Cloudflare.

This is pieced together from [Sherver](https://github.com/remileduc/sherver) and [Cloudflare Dynamic DNS IP Updater](https://github.com/K0p1-Git/cloudflare-ddns-updater).

### How to

 - clone this repo `git clone https://github.com/jeidnx/fritzbox-cloudflare-ddns /opt/fritzbox-cloudflare-ddns`
 - copy update-template.sh to update.sh
 - Edit configuration in update.sh
 - start with ./sherver.sh or run as a service with systemd (see below)

### Requirements

- `bash` to run the script
- `socat` to run the server.
- `curl` to make the api requests.

### SystemD Service

```shell
# Create user to run the server
sudo useradd ddns
# Copy dyndns.service to systemd folder
sudo cp dyndns.service /etc/systemd/system/dyndns.service
# Reload systemd Daemon
sudo systemctl daemon-reload
# Start the service
sudo systemctl start dyndns
```

License
-------

Everything is under MIT License.