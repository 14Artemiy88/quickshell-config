# eww-to-quickshell v85

Player background blur now uses Quickshell Wayland `BackgroundEffect` to blur the content behind the player surface rather than the album cover. The existing player blur toggle is preserved; the numeric setting controls the rounded blur-region radius. Blur strength itself is controlled by the compositor (Niri).
