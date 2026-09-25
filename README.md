# Quickshell Launcher

Packages search uses the official search.nixos.org Elasticsearch backend directly instead of `nix search`, with the current public frontend credentials and official-style query structure.

Features:
- fast package search with 120 ms debounce
- fuzzy/partial matching through Elasticsearch wildcard queries
- package name, pname, description and long description fields
- schema fallback for known NixOS Search indexes
- visible backend error instead of silently showing an empty list
- Enter copies `package # description` to clipboard and closes the launcher

This launcher remains separate from the EWW → Quickshell project.
