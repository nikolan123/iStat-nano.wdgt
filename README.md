# iStat Nano

![screenshot](https://web.archive.org/web/20141021071644im_/http://images.apple.com/downloads/dashboard/status/images/istatnano_20070608171104.jpg)

## About iStat nano

An advanced system monitor in a tiny package. iStat nano is a stunning system monitor widget with beautifly animated menus and transitions.

View detailed stats about CPU usage, memory usage, hard drive space, bandwidth usage, temperatures, fan speeds, battery usage, uptime and the top 5 processes. iStat nano also shows your public IP address, which be can copied to your clipboard using one of the many keyboard shortcuts.

## How to run (tested on Tahoe)

Install the widget in [Widget Porting Toolkit](https://github.com/nikolan123/WidgetPortingToolkit).

Right-click the .wdgt bundle, click Show Package Contents, and locate the `istat_server.py` file. Run it using Python.

## Native plugin replacement status

The original `iStatNano.bundle` plugin has been replaced by `scripts/iStatNanoShim.js`, which waits for a local data server before running the widget setup. Start the server from this widget directory:

```bash
python3 -B istat_server.py
```

The widget reads `http://127.0.0.1:39123/snapshot` once per second. If the server is not running, the widget shows a startup warning instead of loading with empty data.

Use this if you want the external IP value replaced with a fixed string:

```bash
python3 -B istat_server.py --censor-ext-ip
```

- [x] Widget boots without the legacy native `iStatNano.bundle`.
- [x] Widget startup waits for the first successful server snapshot before building the layout.
- [x] CPU summary and per-core graph data are populated from `top` / `sysctl`.
- [x] Memory data is populated from `vm_stat`, `sysctl`, and `vm.swapusage` in the old nano return format.
- [x] Disk usage is populated from `df` and uses the bundled disk icon.
- [x] Network interfaces, IP addresses, totals, and rates are populated from `ifconfig` and `netstat`.
- [x] External IP is fetched by `istat_server.py` and passed through the local snapshot API.
- [x] Battery percentage, time, power source, charging state, cycle count, and health are populated from `pmset`, `PlistBuddy`, and `system_profiler`.
- [x] Uptime, load average, and process count are populated from macOS command output.
- [ ] Temperature sensors are not implemented; the Python stdlib does not expose SMC sensor data.
- [ ] Fan sensors are not implemented; this probably needs an SMC/IOKit collector or helper tool.
- [ ] Per-process app icon lookup is not implemented; process rows fall back to the widget's default icon.
- [ ] SMART temperature monitoring controls are stubbed.
- [ ] Clipboard copying is currently a shim stub and does not write to the macOS pasteboard yet.
