# Raspberry Pi Internet Health Check

A tiny, dependency-free heartbeat service for a Raspberry Pi.

The Pi periodically makes an outbound HTTPS request to an UptimeRobot
**Heartbeat** monitor. If the Pi's internet connection stops working, the
heartbeat stops arriving and UptimeRobot can send an email alert.

This does **not** expose the Pi to the internet and does not require a VPS.

## Architecture

```text
Raspberry Pi
    |
    | HTTPS heartbeat every 60 seconds
    v
UptimeRobot Heartbeat Monitor
    |
    | no heartbeat for the configured grace period
    v
Email alert
```

The UptimeRobot Free plan currently supports heartbeat monitoring and checks
every 5 minutes. The heartbeat URL is generated when you create the monitor.
See UptimeRobot's current documentation for plan details:

- https://uptimerobot.com/pricing/
- https://help.uptimerobot.com/en/articles/11358364-how-to-create-your-first-monitor-on-uptimerobot-quick-setup-guide
- https://help.uptimerobot.com/en/articles/11358441-understanding-uptimerobot-monitor-types-a-guide-to-essential-services

## 1. Create the UptimeRobot monitor

Create an account at:

https://uptimerobot.com/

Then:

1. Add a new monitor.
2. Select **Heartbeat**.
3. Give it a name such as `Raspberry Pi - internet`.
4. Set the heartbeat/grace settings so that missing heartbeats for several
   minutes counts as DOWN.
5. Add your email as an alert contact.
6. Create the monitor.
7. Copy the unique heartbeat URL.

Keep this URL private. Anyone who has it could potentially send a heartbeat
and make the monitor appear healthy.

Because the Free plan checks every 5 minutes, this setup is intended as a
rough "the Pi has probably lost internet" alert rather than an instant
network-failure detector.

## 2. Clone this project on the Pi

Connect to the Pi:

```bash
ssh -i /home/arian/.ssh/id_ed25519_arianpi evilmorty@192.168.8.144
```

Then clone the repository:

```bash
mkdir -p /home/evilmorty/Projects
cd /home/evilmorty/Projects
git clone https://github.com/arianium/pi_health_check.git
cd /home/evilmorty/Projects/pi_health_check
```

## 3. Install the health checker

Run:

```bash
./install.sh
```

It will ask for the UptimeRobot heartbeat URL and store it locally in:

```text
/home/evilmorty/Projects/pi_health_check/.env
```

The file is created with mode `600` so only `evilmorty` can read it.

The installer creates a **systemd user service**. No Python, virtualenv,
pip package, cron package, or other dependency is required.

## 4. Enable the service after reboot

The installer will tell you if user lingering needs to be enabled.

If necessary, run:

```bash
sudo loginctl enable-linger evilmorty
```

This allows the user service to start at boot even when `evilmorty` is not
logged into a graphical/session environment.

Then check:

```bash
systemctl --user status pi-health-check.service
```

You should see:

```text
Active: active (running)
```

## 5. Verify the heartbeat

Follow the service logs:

```bash
journalctl --user -u pi-health-check.service -n 100 -f
```

You should see successful heartbeat messages approximately once per minute.

You can also check the UptimeRobot dashboard. The monitor should become
healthy after the first successful heartbeat.

## Useful commands

Check status:

```bash
systemctl --user status pi-health-check.service
```

Check whether it is running:

```bash
systemctl --user is-active pi-health-check.service
```

Follow logs:

```bash
journalctl --user -u pi-health-check.service -f
```

Show the last 100 log entries:

```bash
journalctl --user -u pi-health-check.service -n 100
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

Disable it:

```bash
systemctl --user disable --now pi-health-check.service
```

## Updating from Git

From the project directory:

```bash
cd /home/evilmorty/Projects/pi_health_check
git pull
systemctl --user restart pi-health-check.service
```

The `.env` file is intentionally ignored by Git, so your heartbeat URL will
not be overwritten by updates.

## How it behaves during an outage

The checker sends a heartbeat every 60 seconds.

If the Pi loses internet:

1. `curl` cannot reach UptimeRobot.
2. The heartbeat is missed.
3. The local service keeps running and tries again on the next cycle.
4. UptimeRobot eventually marks the heartbeat monitor DOWN.
5. UptimeRobot sends the configured email alert.
6. Once internet returns, the next successful heartbeat tells UptimeRobot the
   monitor is back UP.

There is necessarily a delay: the Pi cannot notify an external service while
its internet connection is down, and UptimeRobot's free monitoring operates
on a 5-minute interval.

## Security / privacy notes

- The Pi makes only an outbound HTTPS request.
- No inbound port needs to be opened on the router.
- No SSH access is given to UptimeRobot.
- No Pi credentials are sent.
- The heartbeat URL is a secret credential for this monitor, so do not commit
  `.env` or paste its contents into GitHub.
- The checker sends no custom payload containing personal information.
- The service uses `curl` with a timeout so a broken network cannot leave the
  process hanging indefinitely.

## Files

```text
pi_health_check/
├── .gitignore
├── README.md
├── heartbeat.sh
├── install.sh
└── pi-health-check.service
```
