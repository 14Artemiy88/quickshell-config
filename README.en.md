# quickshell-widgets

[Русский](README.md) | [**English**](README.en.md)

`quickshell-widgets` is a configurable desktop widget collection, dashboard, and keyboard-driven launcher for **Quickshell** on Linux/Wayland. The project is built with QML/Qt Quick, JavaScript, and Bash helpers.

### Features

- **Desktop widgets:** clock with independent typography controls for time, date, and weekday, CPU/RAM and Top Apps, network traffic and connections, audio volume and streams, CAVA, calendar notes and marks, current weather and forecasts, timers and alarms, Player, Mopidy, and desktop notifications.
- **Dashboard:** configurable Today, System, Network, Weather, and Media cards with independent visibility, ordering, sizing, responsive columns, and an in-panel editing mode.
- **Launcher:** applications, Run, windows, clipboard, power, network, packages, Pass, projects, and calculator, plus custom actions and multi-source search. Built-in navigation entries can be independently hidden from the `>` palette. Saved custom actions use the separate `:` prefix (bare `:` lists all complete records), and the palette stays dedicated to built-in navigation.
- **Settings:** grouped navigation, searchable controls, draggable page ordering, reusable controls, and module-specific pages.
- **Notification sender identity:** DND and history-exclusion rules prefer exact desktop IDs; legacy app-name aliases are retained only while uniquely resolvable. Different desktop IDs with the same app name remain independent, and ambiguous name-only senders are not guessed. The per-app `notificationsHistoryIgnoredApps` rule affects only history snapshots (including `replacesId` updates), never popup visibility or the two DND suppression rules; existing history entries are not retroactively deleted.
- **Profiles and themes:** named profiles, scoped Save/Reset, built-in palettes, and custom color themes.
- **OSD:** shared on-screen indicators for system volume/mute, media track changes, and DND state, with independent display duration and animation settings.
- **Scaling:** independent 75–150% UI and font scales for desktop modules and the Settings window; per-widget base font sizes and stored module coordinates remain independent.
- **Global appearance:** a proportional corner-radius scale (50–150%) plus independent border toggles for buttons, input controls, popups, and cards. Defaults preserve the established look; keyboard focus, validation, and settings-search highlights remain visible when ordinary borders are disabled.
- **Motion:** per-module animation styles, easing profiles, and durations.
- **Drag and drop:** shared reordering for Settings, Launcher, Dashboard, Player, Timer, and Mopidy queues/playlists.


### Adaptive presentation for embedded modules

Shared `WidgetWindow` instances pass a presentation context to each embedded module root: `presentationMode` (`compact`, `regular`, or `wide`), `widthBudget` in logical pixels, and `active` to describe whether the surface is visible. `ModuleFrame` inherits this context and also exposes `compactPresentation`, `regularPresentation`, `widePresentation`, and `presentationActive`. By default, the mode is based on logical width: up to and including 260 px is `compact`, 420 px and above is `wide`, and the range in between is `regular`. A module or individual window can explicitly override the mode; the existing `compact` property in `ModuleFrame` remains available for compatibility.

This contract separates module content from the size and state of its host surface: a module selects its layout using the provided mode and width, while `WidgetWindow` continues to own the window, scaling, geometry, and interaction. Adopting the contract does not by itself change a module's current layout. Adaptive variants are migrated incrementally, one module at a time, rather than through a large-scale rewrite. This is an internal foundation for future widget adaptation; no third-party plugin runtime is added.

Adaptive layouts are implemented in Networks, Network traffic, WeatherList, WeatherNow, Player, Volumes, Calendar, Timer, CPU/CPU Graph, TimeWidget, Mopidy, and TopApps. Their `regular` layout remains the baseline. Compact and wide modes change presentation only and must not alter data sources, saved geometry, or user actions. `test_module_presentation_contract.sh` covers the 260/420 px boundaries, modes before geometry is available, explicit overrides, and context propagation from `WidgetWindow` through `ModuleFrame`.

Cava does not have a separate adaptive layout: the graph already fills its allocated surface, while the number of bars, spacing, and sizes are controlled by settings. TopApps preserves user coordinates and the configured base bar length, but its displayed bar length, starting position, and value column adapt together to the actual window width. When the window narrows, its frame narrows too; the configured bar size no longer forces the transparent host surface to be wider than the user's geometry. Dashboard Bento and its cards use a separate sizing system and are not part of the `ModuleFrame` contract.

Manual testing of v1539 found visual issues that static checks could not reproduce: the TimeWidget date, CPU bar spacing, leftover empty space to the right of CPU Graph, TopApps minimum width, and temperatures disappearing in the compact daily forecast. These were corrected in v1540. WeatherNow's adaptive layout was left unchanged because manual evaluation confirmed that it already worked well. Automated checks remain static and fixture-based: actual QML rendering and interaction at real widths must be checked in Quickshell.

In v1541, the regular TimeWidget layout returned to the full configured size for the main clock text: only the date adapts when space is limited, while compact mode proportionally reduces the entire time/date composition. In CPU Graph, segment width now grows proportionally with the gap as the window expands; point density at the base width remains unchanged, and all 51 historical points and smooth scrolling are preserved.

### Notification sender catalog and DND

The DND catalog is built from actual `NotificationServer.onNotification` events. Quickshell remembers only the sender identity (`desktopEntry` or the exact `appName`) and desktop-entry metadata. The catalog exists only in the current process memory; notification titles, bodies, images, and history contents are not stored in it.

KDE Plasma's `NotificationManager.Settings.knownApplications` was evaluated as a possible supplemental source of older senders, but is intentionally not merged into Quickshell's catalog:

- The `org.kde.notificationmanager` QML module and its `Settings` type are available in Plasma, but they would introduce an additional KDE dependency that may not exist in other Quickshell environments.
- `knownApplications` is documented as a list of desktop entries observed when sending notifications. However, its getter returns `groupList()` from the `Applications` section in `plasmanotifyrc` without checking each group's `Seen` flag, so application settings groups can appear as known senders.
- `registerKnownApplication()` adds an entry only if KDE can resolve the desktop ID through `KService` and the application is not marked `NoDisplay`. A sender without a desktop ID, such as `notify-send`, is therefore absent from this list.
- This list is Plasma-owned data and is not populated by events handled by Quickshell's own `NotificationServer`. It can be a useful historical snapshot, but it does not replace observing current notifications.
- KDE's `forgetKnownApplication()` removes an entire application group from `plasmanotifyrc`; it must not be used to delete a DND row because other Plasma notification settings could be lost along with the `Seen` flag.

Actual Quickshell notification events therefore remain the only source of new DND catalog entries. An application appears after Quickshell has really received a notification from it. Previously configured DND rules are restored separately and can still be removed by the user.

#### NotificationServer lifecycle and D-Bus

In Quickshell 0.3.1, `NotificationServer` is based on a process-wide C++ singleton: the `org.freedesktop.Notifications` name belongs to the Quickshell process, not to the lifecycle of an individual QML component. The Notifications toggle therefore controls receiving and displaying notifications inside quickshell-widgets; it does not hand the D-Bus name to another daemon. When the module is disabled, currently tracked cards are closed, and new incoming events are not accepted by the UI or added to history or the sender catalog. To release the name for Dunst, mako, or another server, the Quickshell process must exit. The public Quickshell 0.3.1 QML API does not expose a separate operation for releasing this singleton server.

The QML `NotificationServer` bridge remains loaded after settings initialization, even when the module is disabled. This is intentional: destroying a Loader does not destroy the process-wide C++ singleton or release the D-Bus name. With `keepOnReload: true`, Quickshell re-delivers still-tracked notifications after a shell reload using `lastGeneration`; the handler accepts them again and restores the runtime sender catalog and history. Upserting by notification ID does not create duplicates.

A D-Bus `Notify` call with `replacesId` updates the existing `Notification` object in place and does not emit a second `NotificationServer.notification` signal. The component therefore observes property changes on tracked notifications and batches rapid signals into a single update through `Qt.callLater`. Updated sender fields refresh the DND catalog, while the title, body, and other metadata replace the previous history snapshot with the same ID. The notification is also re-evaluated against the current DND rules.

Quickshell re-registers `NotificationServer` itself after the previous owner of the D-Bus name releases it. This is server-internal behavior; the QML component does not try to register the same name manually or start a competing watcher. There is a startup limitation: if the session bus is not yet connected when the server is first created, or D-Bus object registration fails, the constructor exits before setting up the watcher. In that case the service may not recover automatically, and Quickshell may need to be restarted after the user D-Bus session is ready. If the session bus is available but another server temporarily owns the name, the watcher waits for the name to be released and retries registration.

The notification card's title and body use read-only `TextEdit` elements for selection and Ctrl+C. Do not assign `acceptedMouseButtons` to `TextEdit`: that is not a property of this type. Qt Quick `TextEdit` accepts the left mouse button (and the middle button when selection clipboard is supported), leaving right-click available to the card's `MouseArea` to dismiss the notification.

Implementation references: [Quickshell 0.3.1 NotificationServer documentation](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/) and [NotificationServer source](https://git.outfoxxed.me/quickshell/quickshell/src/commit/b909b4e3eae14f2f003557ba4117c459cccf8a31/src/services/notifications/server.cpp).

### Sender identity and DND rules

- If a notification includes `desktopEntry`, it is the canonical identity. Two different desktop IDs remain separate applications even when their `appName` is identical.
- If one desktop ID sends different `appName` values over time, the catalog retains earlier names as temporary aliases for the current session. Existing unambiguous rules for an old name continue to work; when the checkbox is changed, the rule is migrated to the canonical desktop ID.
- A notification without `desktopEntry` can be associated with a known desktop entry only when exactly one entry has that name. If multiple desktop IDs share the same name, the name-only sender remains a separate ambiguous entry and is not guessed or merged.
- Rules based on `appName` apply to a desktop-backed sender only while the name is unambiguous. If multiple identities match, the old rule is shown separately as ambiguous and can be removed, but it is not applied to several applications at once. Ambiguous name-only rows cannot enable or suppress applications until a reliable desktop ID is available.
- If `desktopEntry` is missing and several senders share the same `appName`, the system cannot prove which application sent the event. DND does not guess the sender. This is a limitation of the protocol data, not a fuzzy-search issue.
- A summary beside the catalog shows the number of senders seen in the current session, senders with and without rules, counts for “Ignore DND”, “Disable”, and “Ignore history”, saved rules without a current sender, and ambiguous entries. The summary is calculated over the entire catalog and is independent of text search, “Show all”, or result limits.
- Hints for the two independent flags reflect the current state of that specific rule, not just what the rule is intended to do.
- `appName` alias history exists only in the current session's runtime catalog. After a restart the catalog is rebuilt from new notifications; previously saved ambiguous or stale names remain separate rules that the user can remove manually.
- When a legacy `appName` rule is first observed unambiguously, it is automatically migrated to the stable desktop ID and saved. Later changes to the displayed application name no longer affect the rule.

These rules prevent toggling DND for one application with a shared display name from accidentally changing another application's behavior. Tests cover repeated events, `appName` changes, migration from name-only identity to desktop ID, two desktop IDs with the same name, removing one of them, and ambiguous legacy rules.

#### Notification app-icon surface and bounds

The Notifications appearance settings include `notificationsShowAppIconBackground` (enabled by default to preserve the existing appearance). Disabling it removes only the `Config.baseColor` surface behind desktop application icons; messenger avatars and notification-provided leading images retain their existing frame surface. The leading visual now renders through a clipped viewport, with the icon `Image` constrained to the viewport's smaller dimension and its source size derived from its final bounds. This prevents oversized or non-square icon sources from painting outside their allocated area while retaining aspect-fit rendering for application icons.


### Adaptive presentation: Networks

The Networks panel now consumes the shared `compact` / `regular` / `wide` presentation contract.
- Compact mode tightens row spacing, padding, icon column and label typography while keeping connection names visible.
- Regular mode preserves the previous row composition and dimensions.
- Wide mode provides more generous spacing and shows an explicit connected/disconnected status label for each profile.
- Network rows receive the host presentation mode from `ModuleFrame`; no backend, connection discovery, or stored geometry behavior changes.

### Adaptive presentation: Network traffic

The upload/download traffic widget also consumes the shared `compact` / `regular` / `wide` presentation contract.
- Compact mode trims row density and prioritizes current transfer speed, hiding accumulated byte totals when horizontal space is tight.
- Regular mode preserves the previous combined `speed / total` value and the existing settings-backed typography.
- Wide mode separates live speed and accumulated total into aligned columns, with the total visually de-emphasized for easier scanning.
- The module keeps its original click-through-to-Networks action, per-direction visibility settings, transfer colors, and MorphGeometry enter/exit animations. No traffic-monitoring backend or stored geometry behavior changes.

### Launcher search and navigation

- The built-in command palette uses the `>` prefix. Dashboard can be opened with `>dashboard`, `>overview`, or `>обзор`. Saved custom actions use the separate `:` prefix and remain independent from built-in navigation.
- Fuzzy search for saved custom actions, color schemes, and wallpapers has independent settings in **Settings → Launcher → Search**. The action-search switch controls saved custom actions; the **Schemes setting** and **Wallpapers setting** independently control matching for color schemes and wallpapers.
- Dynamic color schemes include `Fruit Salad` and `Tonal Spot`. Use `>scheme variants` to open the variant picker; `>variant` is a shorter alias.
- Optional Vim-style navigation is disabled by default. When enabled, `Ctrl+J`/`Ctrl+N` move down and `Ctrl+K`/`Ctrl+P` move up.
- The keyboard navigation hints panel is visible by default and can be hidden independently from Vim-style navigation.

### Dashboard

Dashboard cards are informational and passive: clicking a card surface does not open another view. Open Dashboard settings with the shared Settings control in the upper-right corner. The Dashboard can also be toggled through Quickshell IPC:

```sh
qs -c <path-to-configuration> ipc call dashboard toggle
```

### Requirements

**Required:** Quickshell with Qt Quick/Wayland support, Bash, and `jq`. Network requests and individual integrations also use `curl`, `file`, Python 3, and standard Linux utilities.

Optional integrations may require:

| Feature | Dependencies |
|---|---|
| CAVA | `cava` |
| Networking | NetworkManager and `nmcli` |
| Audio volume | `pactl` and/or `wpctl` |
| Player | D-Bus/MPRIS and a supported media player; some backends use `playerctl` |
| Mopidy | A running Mopidy server with its HTTP JSON-RPC API |
| Clipboard | `cliphist`, `wl-copy`, and a Wayland session |
| Pass | `pass`, `wl-copy` |
| Launcher Windows tab | Niri CLI (`niri`) |
| Terminal command execution | `foot` and Zsh |
| Nix package search | Nix and access to `search.nixos.org` |
| Weather | A Gismeteo API token configured in Settings |

If an optional utility is missing, its integration may be unavailable; the remaining modules continue to work.

### Install and update

Run the installer from the project directory:

```sh
./install.sh
```

It installs the shell configuration into `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell` and preserves existing user data. Start it with:

```sh
quickshell -c "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
```

Use `qs` instead of `quickshell` if that is the executable provided by your distribution. Run the installer again to update the installed files.

### Settings and user data

Settings and profiles are stored under `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell-widgets/`; calendar data defaults to `${XDG_DATA_HOME:-$HOME/.local/share}/quickshell-widgets/`. The weather token is kept in a separate local `secrets.json` file. Storage locations can be changed in **Settings → General → Storage**.

`settings.json` and `profiles.json` are intentionally trackable for users who explicitly want to sync configuration. Review them before committing. Secrets, calendar data, migration markers, temporary files, locks, and recovery backups are ignored by `.gitignore`.

### Development and tests

Run the static and fixture-based regression suite from the repository root:

```sh
bash CHECK.sh
```

Test dependencies: `jq`, `curl`, `file`, Python 3, Node.js, and `gawk`. The suite does not launch a graphical Quickshell session, so visually verify QML changes in the target environment. Add every new `tests/*.sh` script to `CHECK.sh`.

### License

MIT — see [`LICENSE`](LICENSE).
