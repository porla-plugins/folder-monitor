# A folder monitor for Porla

This plugin adds folder monitoring capabilities to Porla.

## Configuration

The plugin is configured directly in the Porla TOML config file.

```toml
[folder-monitor]
# A cron expression to set how often the monitored folders
# should be checked. This example means every 5 seconds.
cron = "*/5 * * * * *"

[[folder-monitor.dirs]]
path = "/home/viktor/watch"
```
