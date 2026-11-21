# Store Setup: Locking the Booth iPad

The booth iPad runs TotalPhotoBooth under **Guided Access**, which locks it to
this one app. Customers can't press Home, swipe to other apps, or open Control
Center. The app can't turn Guided Access on by itself; staff start it with a
triple-click of the Home button. Config shows whether it's on
("Guided Access on" / "off"), and so does the staff menu.

## One-time setup

1. **Turn on Guided Access**: Settings → Accessibility → Guided Access → on.
2. **Passcode Settings**:
   - Set Guided Access Passcode: pick a staff code, separate from the iPad's own passcode.
   - Touch ID: on, so staff can unlock with a fingerprint.
3. **Accessibility Shortcut**: on. A triple-click of Home then starts and ends Guided Access.
4. **Display Auto-Lock** (in the Guided Access settings): **Never**. The kiosk keeps the screen awake
   itself, and the spiral is its screensaver.
5. **Notifications**: set up a Focus (or Do Not Disturb) for store hours, so
   nothing pops over the booth.
6. **Updates**: Settings → General → Software Update → Automatic Updates → off,
   so the iPad never restarts for an update mid-day.
7. **Power and network**: keep the iPad on a charger, on the same Wi-Fi as the
   SELPHY.

## Opening the booth each day

1. Open TotalPhotoBooth. On Config, check the printer and the paper/ink counts.
2. **Triple-click the Home button.** Guided Access shows its setup screen.
3. Tap **Options** and set:
   - Sleep/Wake Button: **off**
   - Volume Buttons: **off**
   - Motion: **off**
   - Software Keyboards: **off**
   - Touch: **on**
   - Time Limit: **off**
4. Tap **Start**. Config now shows "Guided Access on".
   - iPadOS remembers these options for this app, so later days only need steps 2 and 4.
5. Tap **Start Kiosk Mode**.

If you tap Start Kiosk Mode while Guided Access is off, the app warns you first.
**Start Anyway** works for testing, but customers could leave the app.

## During the day

- **Staff menu**: hold two fingers on the screen. From there you can reprint
  any photo from Photos, check paper and ink, or **Exit Kiosk Mode**.
  - Exiting goes back to Config, still inside Guided Access.
- **If the app restarts**: while Guided Access is on, iPadOS reopens the app if
  it ever quits, and the app goes straight back into the kiosk.
- **To unlock the iPad** (for example to clear the Print Center, change
  settings, or close up): triple-click Home, then Touch ID or the passcode, and
  tap **End**.

## Troubleshooting

- **Prints didn't come out.** AirPrint queues jobs even when the printer is off
  or out of paper, so nothing shows as an error. Unlock Guided Access, open the
  App Switcher → Print Center, cancel stuck jobs, then reprint from the staff
  menu.
- **The kiosk wakes on its own, or doesn't wake.** Exit Kiosk Mode, turn on Debug
  Mode on Config, and retune Motion Wake with the live meter.
- **Forgot the Guided Access passcode.** Hold the Sleep/Wake and Home buttons
  together until the Apple logo appears. That force restart should end Guided
  Access. Then set a new code in Settings.
