# Raspberry Pi Internet Health Check

A tiny, dependency-free internet connectivity watchdog for a Raspberry Pi.

The Pi sends an HTTPS heartbeat to Healthchecks.io once per minute. If the
Pi's internet connection stops working, the heartbeat stops arriving and
Healthchecks.io sends an email alert.

No VPS, inbound port, Python package, or public IP is required.

## Why Healthchecks.io?

The free Hobbyist plan currently allows 20 monitored checks. Healthchecks.io
is specifically designed around heartbeat/dead-man-switch monitoring.

Official documentation:

- https://healthchecks.io/
- https://healthchecks.io/pricing/
- https://healthchecks.io/docs/configuring_checks/
- https://healthchecks.io/docs/faq/

## 1. Create the Healthchecks.io check

Create a free account at:

https://healthchecks.io/

Create a new check with these settings:

- **Name:** `Raspberry Pi Internet`
- **Period:** `1 minute`
- **Grace time:** `5 minutes`
- **Notification:** Email

Healthchecks.io calls the generated URL the **Ping URL**.

Copy the Ping URL. It will look approximately like:

```text
https://hc-ping.com/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Keep this URL private. Anyone who has it can send a successful heartbeat to
your check.

The 1-minute period plus 5-minute grace time means a sustained outage should
be reported after roughly five minutes of missed heartbeats. There can be
additional notification/delivery delay.

## 2. Clone this project on the Pi

From your host computer:

```bash
ssh -i /home/arian/.ssh/id_ed25519_arianpi evilmorty@192.168.8.144
```

Then on the Pi:

```bash
mkdir -p /home/evilmorty/Projects
cd /home/evilmorty/Projects
git clone https://github.com/arianium/pi_health_check.git
cd /home/evilmorty/Projects/pi_health_check
```

If you already cloned the previous version, update it instead:

```bash
cd /home/evilmorty/Projects/pi_health_check
git pull
```

## 3. Install the health checker

Run:

```bash
./install.sh
```

It will ask for the Healthchecks.io Ping URL.

The URL is stored locally in:

```text
/home/evilmorty/Projects/pi_health_check/.env
```

The file is created with permissions `600`, so only `evilmorty` can read it.

No Python environment or packages are needed. The checker uses the `curl`
command already normally available on Raspberry Pi OS.

## 4. Start at boot

The installer creates a systemd **user service**.

Check it:

```bash
systemctl --user status pi-health-check.service
```

It should say:

```text
Active: active (running)
```

To make sure it starts after a reboot even when `evilmorty` has not logged in:

```bash
sudo loginctl enable-linger evilmorty
```

You only need to do that once.

## 5. Verify the heartbeat

Follow the local logs:

```bash
journalctl --user -u pi-health-check.service -n 100 -f
```

You should see:

```text
heartbeat OK
```

approximately once per minute.

Also check the Healthchecks.io dashboard. The check should become `Up` after
the first successful ping.

## Useful commands

Status:

```bash
systemctl --user status pi-health-check.service
```

Machine-readable status:

```bash
systemctl --user is-active pi-health-check.service
```

Follow logs:

```bash
journalctl --user -u pi-health-check.service -n 100 -f
```

Restart:

```bash
systemctl --user restart pi-health-check.service
```

Stop:

```bash
systemctl --user stop pi-health-check.service
```

Start:

```bash
systemctl --user start pi-health-check.service
```

Disable:

```bash
systemctl --user disable --now pi-health-check.service
```

## Updating the project

```bash
cd /home/evilmorty/Projects/pi_health_check
git pull
systemctl --user restart pi-health-check.service
```

`.env` is ignored by Git, so the secret Ping URL is not replaced by updates.

## How an outage is detected

The service sends a heartbeat every 60 seconds.

If the Pi loses internet:

1. `curl` cannot reach Healthchecks.io.
2. The heartbeat is missed.
3. The local service stays running and retries.
4. Healthchecks.io sees that the expected heartbeat has not arrived.
5. After the configured grace period, Healthchecks.io marks the check down.
6. Healthchecks.io sends the configured email alert.
7. When the internet returns, the next successful heartbeat marks the check up.

The Pi cannot send an alert while its internet connection is down. That is why
Healthchecks.io is useful: the monitoring and alerting happen outside the Pi.

## Security and privacy

- The Pi only makes outbound HTTPS requests.
- No inbound router port is required.
- Healthchecks.io does not need SSH access to the Pi.
- No Pi password, SSH key, or other credentials are sent.
- The Ping URL is a secret token and should be treated like a password for
  this monitor.
- Do not commit `.env` or paste the Ping URL into GitHub.
- The heartbeat request contains no custom personal information.
- `curl` has a timeout so a broken network cannot leave the checker stuck
  indefinitely.

Healthchecks.io states that it is open source and can also be self-hosted if
you ever want to operate the monitoring service yourself.

## Files

```text
pi_health_check/
├── .gitignore
├── README.md
├── heartbeat.sh
├── install.sh
└── pi-health-check.service
```
