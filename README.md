# Takukku — Solat Notch

> **A tiny piece of sky, living in the MacBook notch.**

Takukku (takukku means *my notch*) is a native macOS menu-bar prayer-time companion for Malaysia. It keeps the next prayer, its countdown, a small weather glance and a living day-gradient close at hand—without becoming another window to manage.

![Latest Solat Notch build](docs/latest-build.png)

## What makes it different

- **Native macOS** — Swift, SwiftUI, AppKit and an `NSPanel`-based notch surface.
- **Prayer times with a source trail** — official Malaysian-zone schedules are fetched through the JAKIM-sourced Waktu Solat API, validated, cached and labelled in the UI.
- **Quiet by design** — no account, analytics, advertising or mandatory internet connection.
- **A day that moves** — the compact notch follows the real prayer interval with a restrained, breathing gradient rather than a looping screensaver.
- **Made for real life** — offline cache, tomorrow’s Subuh, Malaysia timezone handling, local notifications, reduced motion and manual zone selection.
- **Weather-aware** — optionally let the notch’s visual mood follow the prayer timeline or current weather.

## The little experience

Collapsed, Takukku stays out of the way: a three-letter prayer code, the remaining time, a celestial icon, weather and a thin animated colour rail that settles around the bottom edge of the notch.

Expand it with hover or click and the surface opens downward with a compact timeline: current period, next prayer, countdown, today’s six prayer times, source status and the sun/moon position. Click anywhere on the surface to close it again. On Macs without a notch, the same experience becomes a small floating top-centre pill.

## Honest data states

The production path never invents prayer times. Until a real schedule is available it shows a genuine loading or empty state. When offline it uses the last validated schedule for the selected zone. If the user explicitly enables calculation fallback, the UI says **Waktu anggaran** so an estimate is never mistaken for an official schedule.

Source labels are visible in the expanded view and settings:

```text
Sumber: JAKIM melalui Waktu Solat API
Dikemas kini: [real timestamp]
Zon: [real zone code and name]
```

## Current build

The repository contains the native menu-bar shell, DynamicNotchKit integration, real Malaysian provider and validation layer, local cache, zone selector, Core Location suggestion flow, weather service, notification scheduler, settings, localisation and a widget-extension source scaffold.

Run the current build locally:

```sh
./script/build_and_run.sh --verify
```

On first launch, choose and confirm a Malaysian prayer zone. Location can suggest a zone, but it never silently chooses an official schedule for you.

## Under construction (in a good way)

Takukku is deliberately being built in the open. The fun part is not pretending every edge case is finished—it is making each one visible and useful:

- **Notch choreography:** tuning hover, click, full-screen spaces, multiple displays and sleep/wake so expansion feels like one continuous gesture instead of a jump cut.
- **A better sky:** making the gradient rail, horizon glow and sun/moon path feel alive while staying gentle on CPU and GPU.
- **Weather mood:** polishing the prayer-time/weather background switch, live previews and useful weather details.
- **Notifications that respect the room:** device tones, optional azan support, per-prayer reminders, test delivery and Focus/Do Not Disturb behaviour.
- **The settings pass:** native macOS spacing, readable panes, state → zone filtering, sliders that feel good and explanations that answer “why is this here?”.
- **Widgets:** four Apple-sized widget families are scaffolded for countdown, daily times, weekly times and prayer + weather. The final WidgetKit target and App Group wiring are next.
- **Trust before polish:** malformed payloads, stale caches, midnight boundaries and timezone changes get tested before decorative animation gets more ambitious.

## Architecture

The code is split by responsibility so the interface can evolve without rewriting the prayer engine:

```text
Application lifecycle    Notch presentation       Prayer calculations
Timeline calculation     Sky visual engine        Location management
Notifications            Settings                 Localisation
```

`PrayerTimeProvider` keeps the UI independent from the data source. The intended priority is live Malaysian schedule → validated cache → explicitly enabled Adhan Swift calculation fallback.

## Attribution

Malaysian prayer schedules are sourced through [Waktu Solat API](https://api.waktusolat.app/), which documents its JAKIM e-Solat source. The app is not an official JAKIM product. Calculated schedules may differ slightly from official local schedules.

## Licence and status

Takukku is an active work in progress. It is not production-ready yet, and the screenshots are snapshots of the latest local build—not a promise that every planned surface has shipped.
