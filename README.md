fritzbox-cloudflare-ddns
=======

Dynamic DNS with FritzBox and Cloudflare

Easy solution to set up a **local** Dynamic DNS Server if you are running a Fritzbox and using Cloudflare.

This is pieced together from [Sherver](https://github.com/remileduc/sherver) and [Cloudflare Dynamic DNS IP Updater](https://github.com/K0p1-Git/cloudflare-ddns-updater).

### How to

On your server:
```shell
# Clone the repo
git clone https://github.com/jeidnx/fritzbox-cloudflare-ddns /opt/fritzbox-cloudflare-ddns
# Copy the template
cp update-template.sh update.sh
# Insert your Credentials and Domains to update in update.sh
vim update.sh
# Start the server (alternatively start as systemD service, see further below for info)
./sherver.sh
```

To enable DynDNS in your FritzBox
 - Make sure that your server has a static internal IP Address
 - Find the DynDNS Settings page
 - Select Custom for DynDNS-Provider
 - Enter these values, **replace 10.10.10.10 with your servers local IP**
   - Update-Url: `10.10.10.10:8080/update?ip=<ipaddr>`
   - Domain: `it`
   - Username: `doesn't`
   - Password: `matter`

### Requirements

- `bash` to run the script
- `socat` to run the server.
- `curl` to make the api requests.

### SystemD Service

```shell
# Create user to run the server
useradd dyndns
# Copy dyndns.service to systemd folder
cp dyndns.service /etc/systemd/system/dyndns.service
# Reload systemd Daemon
systemctl daemon-reload
# Start the service
systemctl start dyndns
```

License
-------

Everything is under MIT License.