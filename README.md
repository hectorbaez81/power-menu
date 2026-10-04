# Power Menu

A bar glyph (the power symbol) that opens a panel with six session actions:
Log out, Lock, Suspend, Hibernate, Reboot, Power off.

## What runs

- Lock: `ryoku-shell lock`
- Suspend: `ryoku-shell suspend` (the shell takes its secure lock first)
- Hibernate: `bin/hibernate.sh`, which runs `ryoku-shell lock`, waits until the
  `ryoku-idle` journal reports `Wayland session got locked`, then runs
  `systemctl hibernate --check-inhibitors=no`. If the lock is not confirmed within
  about 10 seconds it notifies and does not hibernate.
- Log out: `hyprctl dispatch "hl.dsp.exit()"`
- Reboot / Power off: `systemctl reboot` / `systemctl poweroff`

## What it reads

The `ryoku-idle` lines in the system journal, only in `bin/hibernate.sh`.

## What it writes

Nothing. No files, no network.

## Privileged actions

None through this plugin. Hibernating past the shell's sleep inhibitor needs the
polkit rule `org.freedesktop.login1.hibernate-ignore-inhibit` to be allowed for the
active local session (a system-level rule, not shipped by this plugin).

## Settings (QS Bar Settings > Community)

- Ask before acting: the first click arms a row, the second runs it. Lock never asks.
- Show/hide each of the six actions.
