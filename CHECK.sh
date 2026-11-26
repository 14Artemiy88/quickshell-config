#!/bin/bash
set -e
# Individual tests and steps are guarded by run_test/run_step; failures are aggregated at the end.
ROOT="$(cd "$(dirname "$0")" && pwd)"
CHECK_STARTED=$SECONDS
CHECK_TOTAL="$(grep -oE 'tests/[A-Za-z0-9_.-]+\.sh' "$0" | sort -u | wc -l | tr -d ' ')"
CHECK_CURRENT=0
CHECK_PASSED=0
CHECK_FAILED=0
CHECK_STEP_TOTAL=0
CHECK_STEP_PASSED=0
CHECK_STEP_FAILED=0
CHECK_FAILED_TEST_NAMES=()
CHECK_FAILED_STEP_NAMES=()
CHECK_LOG="$(mktemp)"
CHECK_TIMINGS_FILE="$(mktemp)"

# Emit ANSI colors only to interactive terminals. Respect NO_COLOR and dumb terminals.
CHECK_CYAN_OUT=''
CHECK_GREEN_OUT=''
CHECK_RED_OUT=''
CHECK_RESET_OUT=''
CHECK_CYAN_ERR=''
CHECK_GREEN_ERR=''
CHECK_RED_ERR=''
CHECK_RESET_ERR=''
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
    CHECK_CYAN_OUT=$'\033[36m'
    CHECK_GREEN_OUT=$'\033[32m'
    CHECK_RED_OUT=$'\033[31m'
    CHECK_RESET_OUT=$'\033[0m'
fi
if [[ -t 2 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
    CHECK_CYAN_ERR=$'\033[36m'
    CHECK_GREEN_ERR=$'\033[32m'
    CHECK_RED_ERR=$'\033[31m'
    CHECK_RESET_ERR=$'\033[0m'
fi

finish_check() {
    local status=$?
    trap - EXIT
    local elapsed=$((SECONDS - CHECK_STARTED))
    if [[ -s "$CHECK_TIMINGS_FILE" ]]; then
        printf '\nSlowest tests (top 10 of %s):\n' "$CHECK_CURRENT"
        sort -nr "$CHECK_TIMINGS_FILE" | head -n 10 | awk -F '\t' '{
            printf "  %2d. %-58s %7.3fs\n", NR, $2, $1 / 1000000
        }'
    fi
    rm -f -- "$CHECK_LOG" "$CHECK_TIMINGS_FILE"
    if ((status == 0)); then
        printf '\n%sCHECK COMPLETE%s: %s%s/%s tests passed%s, %s%s failed%s | steps %s/%s passed, %s failed | %ss\n' \
            "$CHECK_CYAN_OUT" "$CHECK_RESET_OUT" "$CHECK_GREEN_OUT" "$CHECK_PASSED" "$CHECK_TOTAL" \
            "$CHECK_RESET_OUT" "$CHECK_RED_OUT" "$CHECK_FAILED" "$CHECK_RESET_OUT" \
            "$CHECK_STEP_PASSED" "$CHECK_STEP_TOTAL" "$CHECK_STEP_FAILED" "$elapsed"
    elif ((status == 130 || status == 143)); then
        printf '\n%sCHECK INTERRUPTED%s: %s%s/%s tests passed%s, %s%s failed%s | steps %s/%s passed, %s failed | stopped after %ss (exit %s)\n' \
            "$CHECK_CYAN_ERR" "$CHECK_RESET_ERR" "$CHECK_GREEN_ERR" "$CHECK_PASSED" "$CHECK_TOTAL" \
            "$CHECK_RESET_ERR" "$CHECK_RED_ERR" "$CHECK_FAILED" "$CHECK_RESET_ERR" \
            "$CHECK_STEP_PASSED" "$CHECK_STEP_TOTAL" "$CHECK_STEP_FAILED" "$elapsed" "$status" >&2
    else
        printf '\n%sCHECK FAILED%s: %s%s/%s tests passed%s, %s%s failed%s | steps %s/%s passed, %s failed | %ss (exit %s)\n' \
            "$CHECK_RED_ERR" "$CHECK_RESET_ERR" "$CHECK_GREEN_ERR" "$CHECK_PASSED" "$CHECK_TOTAL" \
            "$CHECK_RESET_ERR" "$CHECK_RED_ERR" "$CHECK_FAILED" "$CHECK_RESET_ERR" \
            "$CHECK_STEP_PASSED" "$CHECK_STEP_TOTAL" "$CHECK_STEP_FAILED" "$elapsed" "$status" >&2
    fi

    if ((${#CHECK_FAILED_TEST_NAMES[@]})); then
        printf '\nFailed tests:\n' >&2
        printf '  - %s\n' "${CHECK_FAILED_TEST_NAMES[@]}" >&2
    fi
    if ((${#CHECK_FAILED_STEP_NAMES[@]})); then
        printf '\nFailed steps:\n' >&2
        printf '  - %s\n' "${CHECK_FAILED_STEP_NAMES[@]}" >&2
    fi
}
trap finish_check EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

check_now_us() {
    # Read EPOCHREALTIME exactly once: it is a special variable whose value
    # changes on every expansion. Reading seconds and fraction separately can
    # combine two different instants at a second boundary and corrupt timings.
    local raw seconds fraction now_ns
    raw="${EPOCHREALTIME:-}"
    if [[ -n "$raw" && "$raw" == *.* ]]; then
        seconds="${raw%%.*}"
        fraction="${raw#*.}000000"
        fraction="${fraction:0:6}"
        CHECK_NOW_US="${seconds}${fraction}"
    else
        # GNU date fallback. Keep the first 16 digits (epoch seconds + usec)
        # without arithmetic on the full nanosecond timestamp.
        now_ns="$(date +%s%N)"
        if [[ "$now_ns" =~ ^[0-9]{19}$ ]]; then
            CHECK_NOW_US="${now_ns:0:16}"
        else
            seconds="$(date +%s)"
            CHECK_NOW_US="${seconds}000000"
        fi
    fi
}

run_test() {
    local script="$1" name="${1##*/}" status start_us end_us elapsed_us
    CHECK_CURRENT=$((CHECK_CURRENT + 1))
    check_now_us
    start_us="$CHECK_NOW_US"
    if bash "$script" >"$CHECK_LOG" 2>&1; then
        CHECK_PASSED=$((CHECK_PASSED + 1))
        printf '[%03d/%03d] %sPASS%s %s\n' \
            "$CHECK_CURRENT" "$CHECK_TOTAL" "$CHECK_GREEN_OUT" "$CHECK_RESET_OUT" "$name"
    else
        status=$?
        CHECK_FAILED=$((CHECK_FAILED + 1))
        CHECK_FAILED_TEST_NAMES+=("$name (exit $status)")
        printf '[%03d/%03d] %sFAIL%s %s (exit %s) — continuing\n' \
            "$CHECK_CURRENT" "$CHECK_TOTAL" "$CHECK_RED_ERR" "$CHECK_RESET_ERR" "$name" "$status" >&2
        if [[ -s "$CHECK_LOG" ]]; then
            cat "$CHECK_LOG" >&2
        else
            printf '  (test produced no output)\n' >&2
        fi
    fi
    check_now_us
    end_us="$CHECK_NOW_US"
    elapsed_us=$((10#$end_us - 10#$start_us))
    ((elapsed_us < 0)) && elapsed_us=0
    printf '%s\t%s\n' "$elapsed_us" "$name" >>"$CHECK_TIMINGS_FILE"
}

run_step() {
    local name="$1"; shift
    local status
    CHECK_STEP_TOTAL=$((CHECK_STEP_TOTAL + 1))
    if "$@" >"$CHECK_LOG" 2>&1; then
        CHECK_STEP_PASSED=$((CHECK_STEP_PASSED + 1))
        printf '%s[STEP]%s %sPASS%s %s\n' \
            "$CHECK_CYAN_OUT" "$CHECK_RESET_OUT" "$CHECK_GREEN_OUT" "$CHECK_RESET_OUT" "$name"
    else
        status=$?
        CHECK_STEP_FAILED=$((CHECK_STEP_FAILED + 1))
        CHECK_FAILED_STEP_NAMES+=("$name (exit $status)")
        printf '%s[STEP]%s %sFAIL %s (exit %s) — continuing%s\n' \
            "$CHECK_CYAN_ERR" "$CHECK_RESET_ERR" "$CHECK_RED_ERR" "$name" "$status" "$CHECK_RESET_ERR" >&2
        if [[ -s "$CHECK_LOG" ]]; then
            cat "$CHECK_LOG" >&2
        else
            printf '  (step produced no output)\n' >&2
        fi
    fi
}
run_test "$ROOT/tests/test_env_source_fastpath.sh"
run_test "$ROOT/tests/test_env_project_root_builtin.sh"
run_test "$ROOT/tests/test_check_timing_report.sh"
run_test "$ROOT/tests/test_test_audit_inventory.sh"

# Notifications
QML_COUNT="$(find "$ROOT" -type f -name '*.qml' | wc -l | tr -d ' ')"
printf '%sCHECK%s: %s QML files, %s shell tests\n' \
    "$CHECK_CYAN_OUT" "$CHECK_RESET_OUT" "$QML_COUNT" "$CHECK_TOTAL"
run_test "$ROOT/tests/test_notifications_config_and_null_safety.sh"
run_test "$ROOT/tests/test_notifications_timeout_units.sh"
run_test "$ROOT/tests/test_notifications_default_timeout.sh"
run_test "$ROOT/tests/test_notifications_timeout_indicator.sh"
run_test "$ROOT/tests/test_notifications_timeout_perimeter.sh"
run_test "$ROOT/tests/test_notifications_timeout_direction.sh"
run_test "$ROOT/tests/test_notifications_hover_timeout_pause.sh"
run_test "$ROOT/tests/test_notifications_countdown_smoothness.sh"
run_test "$ROOT/tests/test_notifications_progress_hint.sh"
run_test "$ROOT/tests/test_notifications_default_action_click.sh"
run_test "$ROOT/tests/test_notifications_right_click_dismiss.sh"
run_test "$ROOT/tests/test_notifications_markup_links.sh"
run_test "$ROOT/tests/test_notifications_kde_html_tags.sh"
run_test "$ROOT/tests/test_notifications_span_markup.sh"
run_test "$ROOT/tests/test_notifications_literal_html_characters.sh"
run_test "$ROOT/tests/test_notifications_app_icon.sh"
run_test "$ROOT/tests/test_notifications_app_icon_fallback.sh"
run_test "$ROOT/tests/test_notifications_image_hint.sh"
run_test "$ROOT/tests/test_notifications_messenger_avatar.sh"
run_test "$ROOT/tests/test_notifications_square_image_leading_icon.sh"
run_test "$ROOT/tests/test_notifications_uniform_leading_visual.sh"
run_test "$ROOT/tests/test_notifications_typography_visual_size.sh"
run_test "$ROOT/tests/test_notifications_appearance_controls.sh"
run_test "$ROOT/tests/test_notifications_body_font_override.sh"
run_test "$ROOT/tests/test_notifications_background_color_settings.sh"
run_test "$ROOT/tests/test_notifications_invalid_body_image_fallback.sh"
run_test "$ROOT/tests/test_notifications_adaptive_body_height.sh"
run_test "$ROOT/tests/test_notifications_long_summary_wrap.sh"
run_test "$ROOT/tests/test_notifications_height_binding_loop.sh"
run_test "$ROOT/tests/test_notifications_empty_body_compact.sh"
run_test "$ROOT/tests/test_notifications_empty_summary_compact.sh"
run_test "$ROOT/tests/test_notifications_short_body_compact.sh"
run_test "$ROOT/tests/test_notifications_scrollable_queue.sh"
run_test "$ROOT/tests/test_notifications_hidden_queue_timeout.sh"
run_test "$ROOT/tests/test_notifications_animation_settings.sh"
run_test "$ROOT/tests/test_notifications_animation_direction.sh"
run_test "$ROOT/tests/test_notifications_animation_diagnostics_cleanup.sh"
run_test "$ROOT/tests/test_notifications_animation_closed_signal.sh"
run_test "$ROOT/tests/test_notifications_panel_mapping.sh"
run_test "$ROOT/tests/test_notifications_blur_region_and_queue_reflow.sh"
run_test "$ROOT/tests/test_notifications_dnd.sh"
run_test "$ROOT/tests/test_notifications_dnd_exceptions.sh"
run_test "$ROOT/tests/test_notifications_dnd_search.sh"
run_test "$ROOT/tests/test_notifications_sender_catalog.sh"
run_test "$ROOT/tests/test_notifications_sender_identity_audit.sh"
run_test "$ROOT/tests/test_notifications_dnd_catalog_summary.sh"
run_test "$ROOT/tests/test_notifications_known_applications_policy.sh"
run_test "$ROOT/tests/test_notifications_dnd_remove_app.sh"
run_test "$ROOT/tests/test_notifications_history_ui.sh"
run_test "$ROOT/tests/test_notifications_history_grouping.sh"
run_test "$ROOT/tests/test_notifications_history_delete.sh"
run_test "$ROOT/tests/test_notifications_history_group_delete.sh"
run_test "$ROOT/tests/test_notifications_history_search.sh"
run_test "$ROOT/tests/test_notifications_history_app_filter.sh"
run_test "$ROOT/tests/test_dashboard_history_filter_popup_overlay_guard.sh"
run_test "$ROOT/tests/test_notifications_history_limit_settings.sh"
run_test "$ROOT/tests/test_notifications_history_management.sh"
run_test "$ROOT/tests/test_notifications_history_upsert.sh"
run_test "$ROOT/tests/test_notifications_server_lifecycle.sh"

# Launcher and CI/release checks
run_test "$ROOT/tests/test_launcher_integration.sh"
run_test "$ROOT/tests/test_launcher_module_entry.sh"
run_test "$ROOT/tests/test_launcher_settings_folder_and_hint_panel.sh"
run_test "$ROOT/tests/test_launcher_apps_enter_activation.sh"
run_test "$ROOT/tests/test_application_search_shared.sh"
run_test "$ROOT/tests/test_launcher_action_prefix.sh"
run_test "$ROOT/tests/test_launcher_builtin_action_visibility.sh"
run_test "$ROOT/tests/test_launcher_action_metadata.sh"
run_test "$ROOT/tests/test_launcher_custom_actions.sh"
run_test "$ROOT/tests/test_launcher_custom_actions_discovery.sh"
run_test "$ROOT/tests/test_launcher_custom_action_prefix.sh"
run_test "$ROOT/tests/test_launcher_custom_actions_cross_context.sh"
run_test "$ROOT/tests/test_launcher_custom_action_command_commit.sh"
run_test "$ROOT/tests/test_launcher_custom_action_validation.sh"
run_test "$ROOT/tests/test_launcher_custom_action_profile_override_semantics.sh"
run_test "$ROOT/tests/test_launcher_calculator_and_pointer_hover.sh"
run_test "$ROOT/tests/test_launcher_calculator_edge_cases.sh"
run_test "$ROOT/tests/test_launcher_calculator_history.sh"
run_test "$ROOT/tests/test_launcher_emoji_picker.sh"
run_test "$ROOT/tests/test_launcher_emoji_preferences.sh"
run_test "$ROOT/tests/test_launcher_emoji_views.sh"
run_test "$ROOT/tests/test_launcher_wallpaper_picker.sh"
run_test "$ROOT/tests/test_launcher_wallpaper_random.sh"
run_test "$ROOT/tests/test_launcher_wallpaper_preferences.sh"
run_test "$ROOT/tests/test_launcher_wallpaper_restore.sh"
run_test "$ROOT/tests/test_launcher_wallpaper_scripts.sh"
run_test "$ROOT/tests/test_launcher_scheme_picker.sh"
run_test "$ROOT/tests/test_launcher_dynamic_scheme.sh"
run_test "$ROOT/tests/test_launcher_dynamic_scheme_notifications.sh"
run_test "$ROOT/tests/test_launcher_scheme_variant_picker.sh"
run_test "$ROOT/tests/test_launcher_scheme_variant_persistence.sh"
run_test "$ROOT/tests/test_launcher_frame_background.sh"
run_test "$ROOT/tests/test_launcher_geometry_smart_edit.sh"
run_test "$ROOT/tests/test_launcher_preferences_hover.sh"
run_test "$ROOT/tests/test_launcher_tabs_settings.sh"
run_test "$ROOT/tests/test_launcher_tab_label_icon_customization.sh"
run_test "$ROOT/tests/test_launcher_appearance_settings.sh"
run_test "$ROOT/tests/test_launcher_animation_settings.sh"
run_test "$ROOT/tests/test_launcher_vim_keybinds.sh"
run_test "$ROOT/tests/test_launcher_navigation_hints_visibility.sh"
run_test "$ROOT/tests/test_launcher_navigation_hints_style_settings.sh"
run_test "$ROOT/tests/test_launcher_keyboard_selection_and_focus_recovery.sh"
run_test "$ROOT/tests/test_launcher_cyclic_navigation.sh"
run_test "$ROOT/tests/test_launcher_title_position_color.sh"
run_test "$ROOT/tests/test_launcher_explicit_frame_headings.sh"
run_test "$ROOT/tests/test_launcher_item_radius_and_search_clear.sh"
run_test "$ROOT/tests/test_launcher_async_focus_close_race.sh"
run_test "$ROOT/tests/test_launcher_async_search_race.sh"
run_test "$ROOT/tests/test_launcher_async_tab_data_races.sh"
run_test "$ROOT/tests/test_launcher_projects_tab.sh"
run_test "$ROOT/tests/test_launcher_projects_highlight.sh"
run_test "$ROOT/tests/test_ci_test_coverage.sh"
run_test "$ROOT/tests/test_check_output_format.sh"
run_test "$ROOT/tests/test_check_continue_after_failure.sh"
run_test "$ROOT/tests/test_check_output_colors.sh"
run_test "$ROOT/tests/test_github_actions_ci_workflow.sh"
run_test "$ROOT/tests/test_github_release_cleanliness.sh"
run_test "$ROOT/tests/test_launcher_terminal_persistence.sh"
run_test "$ROOT/tests/test_launcher_run_history_load_race.sh"
run_test "$ROOT/tests/test_launcher_run_history_serial_writes.sh"

# Script entrypoints, Player, and CPU smoke checks
run_step "Bash syntax" bash -c 'find "$1/scripts" -type f ! -name "*.lua" ! -name "*.py" -print0 | while IFS= read -r -d "" f; do bash -n "$f"; done' _ "$ROOT"
run_test "$ROOT/tests/test_cava_stream_filter_single_process.sh"
run_test "$ROOT/tests/test_script_dir_builtin_fastpath.sh"
run_test "$ROOT/tests/test_system_monitor_script_dir_builtin_fastpath.sh"
run_test "$ROOT/tests/test_player_script_dir_builtin_fastpath.sh"
run_test "$ROOT/tests/test_player_long_fallback_text_wrap.sh"
run_test "$ROOT/tests/test_player_time_font_persistence_roundtrip.sh"
run_step "CPU JSON smoke" bash -c 'tmp="$(mktemp)"; trap "rm -f \"$tmp\"" EXIT; status=0; timeout 4s "$1/scripts/cpu_stats" >"$tmp" || status=$?; [[ "$status" -eq 0 || "$status" -eq 124 ]] || exit "$status"; python3 -c "import json,sys; x=json.loads(open(sys.argv[1], encoding=\"utf-8\").readline()); assert isinstance(x[\"cpu\"], list); assert \"ram\" in x; print(len(x[\"cpu\"]), \"cores\")" "$tmp"' _ "$ROOT"
run_test "$ROOT/tests/test_xdg_migration.sh"
run_test "$ROOT/tests/test_profiles_separate_file.sh"
run_test "$ROOT/tests/test_settings_color_field_focus_commit.sh"
run_test "$ROOT/tests/test_storage_paths_command.sh"
run_test "$ROOT/tests/test_storage_paths_safe_relocation.sh"
run_test "$ROOT/tests/test_storage_gitignore_nested_paths.sh"
run_test "$ROOT/tests/test_storage_cleanup.sh"
run_test "$ROOT/tests/test_settings_general_storage_paths_ui.sh"

# Calendar visibility, compositor surfaces, and animation behavior
run_test "$ROOT/tests/test_calendar_notes_concurrency.sh"
run_test "$ROOT/tests/test_calendar_notes_whitespace_fastpath.sh"
run_test "$ROOT/tests/test_calendar_notes_shared_service.sh"
run_test "$ROOT/tests/test_calendar_hidden_window_input_region.sh"
run_test "$ROOT/tests/test_calendar_networks_window_layer_order.sh"
run_test "$ROOT/tests/test_animated_visibility_slide_exit.sh"
run_test "$ROOT/tests/test_visibility_surfaces_none_no_compositor_fade.sh"
run_test "$ROOT/tests/test_animated_visibility_hidden_state.sh"
run_test "$ROOT/tests/test_animated_visibility_style_change.sh"
run_test "$ROOT/tests/test_animation_profiles_and_shared_progress.sh"
run_test "$ROOT/tests/test_animation_expressive_curves.sh"
run_test "$ROOT/tests/test_animation_none_profile.sh"
run_test "$ROOT/tests/test_animation_expressive_morph_integration.sh"
run_test "$ROOT/tests/test_animation_expressive_component_expansion.sh"
run_test "$ROOT/tests/test_animation_expressive_morph_expansion_2.sh"
run_test "$ROOT/tests/test_animation_expressive_mopidy_content_expansion.sh"
run_test "$ROOT/tests/test_animation_expressive_mopidy_top_panel_expansion.sh"
run_test "$ROOT/tests/test_animation_spatial_scale_morph.sh"
run_test "$ROOT/tests/test_animation_geometry_frozen_mid_transition.sh"
run_test "$ROOT/tests/test_animation_reversal_uses_remaining_duration.sh"
run_test "$ROOT/tests/test_animation_panel_instances_independent.sh"
run_test "$ROOT/tests/test_animation_morph_geometry_interpolation.sh"
run_test "$ROOT/tests/test_settings_visibility_cached_content.sh"
run_test "$ROOT/tests/test_animated_visibility_module_none.sh"
run_test "$ROOT/tests/test_animation_none_forces_zero_duration.sh"
run_test "$ROOT/tests/test_calendar_visibility_animation_duration.sh"
run_test "$ROOT/tests/test_mopidy_hidden_window_input_region.sh"
run_test "$ROOT/tests/test_mopidy_top_panel_hide_signal_connection.sh"
run_test "$ROOT/tests/test_mopidy_top_panel_component.sh"
run_test "$ROOT/tests/test_mopidy_playlist_dialog_component.sh"
run_test "$ROOT/tests/test_mopidy_playlist_dialog_morph.sh"
run_test "$ROOT/tests/test_mopidy_add_notice_morph.sh"
run_test "$ROOT/tests/test_mopidy_playlist_contents_component.sh"
run_test "$ROOT/tests/test_mopidy_playlist_top_insertion_slot.sh"
run_test "$ROOT/tests/test_mopidy_queue_row_components.sh"
run_test "$ROOT/tests/test_mopidy_tracklist_move_backend.sh"
run_test "$ROOT/tests/test_mopidy_playlist_move_backend.sh"
run_test "$ROOT/tests/test_mopidy_queue_reorder_geometry.sh"
run_test "$ROOT/tests/test_mopidy_reorder_navigation_lock.sh"
run_test "$ROOT/tests/test_mopidy_queue_artist_line_morph.sh"
run_test "$ROOT/tests/test_mopidy_track_artist_gap_setting.sh"
run_test "$ROOT/tests/test_mopidy_one_line_artist_separator.sh"
run_test "$ROOT/tests/test_mopidy_search_result_metadata_morph.sh"
run_test "$ROOT/tests/test_mopidy_artist_metadata_morph_batch.sh"
run_test "$ROOT/tests/test_mopidy_background_persistence.sh"
run_test "$ROOT/tests/test_mopidy_library_view_component.sh"
run_test "$ROOT/tests/test_mopidy_browse_folder_cover.sh"
run_test "$ROOT/tests/test_mopidy_browse_cover_modes_lazy_loading.sh"
run_test "$ROOT/tests/test_mopidy_browse_cover_hover_exit_option.sh"
run_test "$ROOT/tests/test_mopidy_shared_action_buttons.sh"
run_test "$ROOT/tests/test_mopidy_file_filter.sh"

# Mopidy controls, metadata, and fast paths
run_step "Mopidy resume mock" bash "$ROOT/test_mopidy_resume_mock.sh"
run_test "$ROOT/tests/test_mopidy_shared_row_height.sh"
run_test "$ROOT/tests/test_mopidy_alignment_folder_navigation.sh"
run_test "$ROOT/tests/test_mopidy_queue_duration_anchor_geometry.sh"
run_test "$ROOT/tests/test_mopidy_tab_click_to_queue.sh"
run_test "$ROOT/tests/test_mopidy_tracklist_batched_parse.sh"
run_test "$ROOT/tests/test_mopidy_position_poll_fast_path.sh"
run_test "$ROOT/tests/test_mopidy_combined_status_poll.sh"
run_test "$ROOT/tests/test_mopidy_mixer_batched_get.sh"
run_test "$ROOT/tests/test_mopidy_fast_volume_mute.sh"
run_test "$ROOT/tests/test_mopidy_pulse_mute_fastpath.sh"
run_test "$ROOT/tests/test_mopidy_player_metadata_batched_parse.sh"
run_test "$ROOT/tests/test_mopidy_player_artist_fallback.sh"
run_test "$ROOT/tests/test_mopidy_time_format_inline.sh"
run_test "$ROOT/tests/test_mopidy_remaining_time_sign.sh"
run_test "$ROOT/tests/test_mopidy_cover_key_builtin_parse.sh"
run_test "$ROOT/tests/test_mopidy_cache_dir_mkdir_fastpath.sh"
run_test "$ROOT/tests/test_mopidy_cover_timestamp_fastpath.sh"
run_test "$ROOT/tests/test_mopidy_cover_validation_single_pass.sh"
run_test "$ROOT/tests/test_cpu_graph_modes.sh"
run_test "$ROOT/tests/test_graph_mode_lazy_instantiation.sh"
run_test "$ROOT/tests/test_cava_hide_zero_bars.sh"
run_test "$ROOT/tests/test_cava_silence_morph.sh"
run_test "$ROOT/tests/test_cava_settings_placement.sh"
run_test "$ROOT/tests/test_settings_cava_hide_zero_bars_morph.sh"
run_test "$ROOT/tests/test_segment_bar_graph_primitive.sh"
run_test "$ROOT/tests/test_cava_incremental_value_model.sh"
run_test "$ROOT/tests/test_progress_track_primitive.sh"
run_test "$ROOT/tests/test_cpu_bar_smoothing.sh"
run_test "$ROOT/tests/test_audio_entrypoint_path_fastpath.sh"
run_test "$ROOT/tests/test_audio_volume_builtin_parse.sh"
run_test "$ROOT/tests/test_volume_mute_toggle_stability.sh"
run_test "$ROOT/tests/test_volume_mute_track_behavior.sh"
run_test "$ROOT/tests/test_volume_stream_optimistic_click.sh"
run_test "$ROOT/tests/test_volume_right_click_stream_toggle.sh"
run_test "$ROOT/tests/test_volume_stream_animation_settings.sh"
run_test "$ROOT/tests/test_volume_streams_hidden_compact_height.sh"
run_test "$ROOT/tests/test_volume_stream_settings_morph.sh"
run_test "$ROOT/tests/test_volume_stream_font_override.sh"
run_test "$ROOT/tests/test_volume_stream_animation_duration_morph.sh"
run_test "$ROOT/tests/test_volume_animation_settings.sh"
run_test "$ROOT/tests/test_cpu_track_colors.sh"
run_test "$ROOT/tests/test_cpu_ram_direction.sh"
run_test "$ROOT/tests/test_cpu_widget_lazy_layout.sh"
run_test "$ROOT/tests/test_cpu_widget_single_poll.sh"
run_test "$ROOT/tests/test_cpu_sample_window.sh"
run_test "$ROOT/tests/test_cpu_stats_formula.sh"
run_test "$ROOT/tests/test_cpu_sampling_inline_assignments.sh"
run_test "$ROOT/tests/test_cpu_snapshot_no_per_core_subprocess.sh"
run_test "$ROOT/tests/test_cpu_graph_data_validation.sh"
run_test "$ROOT/tests/test_cpu_graph_flowing.sh"
run_test "$ROOT/tests/test_cpu_memory_consistency.sh"
run_test "$ROOT/tests/test_cpu_graph_accounting.sh"
run_test "$ROOT/tests/test_cpu_graph_sample_inline_assignment.sh"
run_test "$ROOT/tests/test_cpu_graph_state_parse_builtin.sh"
run_test "$ROOT/tests/test_top_apps_split_modules.sh"
run_test "$ROOT/tests/test_top_apps_plasma_style.sh"
run_test "$ROOT/tests/test_top_apps_process_grouping.sh"
run_test "$ROOT/tests/test_top_apps_aggregate_sort_inline.sh"
run_test "$ROOT/tests/test_top_apps_ide_attribution.sh"
run_test "$ROOT/tests/test_top_apps_cpu_delta.sh"
run_test "$ROOT/tests/test_top_apps_bash_state_counter_read.sh"
run_test "$ROOT/tests/test_top_apps_system_load_percent.sh"
run_test "$ROOT/tests/test_top_apps_system_load_inline_assignment.sh"
run_test "$ROOT/tests/test_top_apps_aggregate_cpu_counter_inline.sh"
run_test "$ROOT/tests/test_top_apps_system_load_builtin_read.sh"
run_test "$ROOT/tests/test_top_apps_nonempty_snapshot.sh"
run_test "$ROOT/tests/test_top_apps_resource_capacity_ratios.sh"
run_test "$ROOT/tests/test_top_apps_capacity_builtin_parsing.sh"
run_test "$ROOT/tests/test_top_apps_capacity_inline_assignments.sh"
run_test "$ROOT/tests/test_top_apps_system_cpu_remainder.sh"
run_test "$ROOT/tests/test_top_apps_remainder_single_pass.sh"
run_test "$ROOT/tests/test_top_apps_remainder_settings.sh"
run_test "$ROOT/tests/test_top_apps_batch_formatting.sh"
run_test "$ROOT/tests/test_top_apps_combined_json_encode.sh"
run_test "$ROOT/tests/test_top_apps_selective_aggregation.sh"
run_test "$ROOT/tests/test_top_apps_ram_only_snapshot.sh"
run_test "$ROOT/tests/test_top_apps_ram_only_streaming_fastpath.sh"
run_test "$ROOT/tests/test_top_apps_display_settings.sh"
run_test "$ROOT/tests/test_top_apps_bar_colors.sh"
run_test "$ROOT/tests/test_top_apps_bar_reset_scope.sh"
run_test "$ROOT/tests/test_top_apps_typography_settings.sh"
run_test "$ROOT/tests/test_top_apps_settings_grouping.sh"
run_test "$ROOT/tests/test_top_apps_subheading_frames.sh"
run_test "$ROOT/tests/test_top_apps_value_column_width.sh"
run_test "$ROOT/tests/test_top_apps_value_column_width_single_pass.sh"
run_test "$ROOT/tests/test_top_apps_bar_geometry_settings.sh"
run_test "$ROOT/tests/test_top_apps_bar_settings_morph.sh"
run_test "$ROOT/tests/test_top_apps_headers_remainder_morph.sh"
run_test "$ROOT/tests/test_top_apps_bar_width_unconstrained.sh"
run_test "$ROOT/tests/test_top_apps_bar_overlay_stable_values.sh"
run_test "$ROOT/tests/test_top_apps_qml_delimiters.sh"

# Settings, profiles, resets, and Timer regressions
run_test "$ROOT/tests/test_hover_icon_button_primitive.sh"
run_test "$ROOT/tests/test_settings_animation_group_primitive.sh"
run_test "$ROOT/tests/test_settings_dependent_controls_consistency.sh"
run_test "$ROOT/tests/test_settings_label_primitive.sh"
run_test "$ROOT/tests/test_settings_row_primitive.sh"
run_test "$ROOT/tests/test_mopidy_settings_icon_order_arrows.sh"
run_test "$ROOT/tests/test_settings_button_frame_hover.sh"
run_test "$ROOT/tests/test_drag_reorder_primitive.sh"
run_test "$ROOT/tests/test_drag_reorder_indicator_alignment.sh"
run_test "$ROOT/tests/test_drag_reorder_indicator_motion.sh"
run_test "$ROOT/tests/test_dashboard_drag_reorder_index_binding.sh"
run_test "$ROOT/tests/test_settings_reset_button_primitive.sh"
run_test "$ROOT/tests/test_settings_save_button_primitive.sh"
run_test "$ROOT/tests/test_profile_delete_button_states.sh"
run_test "$ROOT/tests/test_profile_management_guardrails.sh"
run_test "$ROOT/tests/test_reset_buttons_hidden_without_profile.sh"
run_test "$ROOT/tests/test_reset_button_change_tracking.sh"
run_test "$ROOT/tests/test_reset_buttons_use_sparse_overrides.sh"
run_test "$ROOT/tests/test_reset_visibility_scope_coverage.sh"
run_test "$ROOT/tests/test_active_profile_groupbox_and_hidden_buttons.sh"
run_test "$ROOT/tests/test_launcher_background_and_settings_window_color.sh"
run_test "$ROOT/tests/test_settings_window_smart_edit_frame.sh"
run_test "$ROOT/tests/test_settings_modules_smart_edit_exit_layout.sh"
run_test "$ROOT/tests/test_settings_tabs_customization.sh"
run_test "$ROOT/tests/test_settings_tabs_normalization.sh"
run_test "$ROOT/tests/test_settings_tab_dirty_indicators.sh"
run_test "$ROOT/tests/test_notifications_settings_module.sh"
run_test "$ROOT/tests/test_notifications_module_size_controls.sh"
run_test "$ROOT/tests/test_notifications_absolute_geometry.sh"
run_test "$ROOT/tests/test_notifications_geometry_smart_edit.sh"
run_test "$ROOT/tests/test_notifications_vertical_anchor.sh"
run_test "$ROOT/tests/test_settings_subtab_and_frame_dirty_indicators.sh"
run_test "$ROOT/tests/test_settings_frame_indicator_coverage.sh"
run_test "$ROOT/tests/test_module_blur_settings_integration.sh"
run_test "$ROOT/tests/test_timer_preset_button_primitive.sh"
run_test "$ROOT/tests/test_timer_comment_adaptive_spacing.sh"
run_test "$ROOT/tests/test_timer_comment_align_furthest.sh"
run_test "$ROOT/tests/test_timer_json_escaping.sh"
run_test "$ROOT/tests/test_timer_state_concurrency.sh"
run_test "$ROOT/tests/test_timer_tempfile_permissions_fastpath.sh"
run_test "$ROOT/tests/test_timer_lock_releases_on_fd_close.sh"
run_test "$ROOT/tests/test_timer_daemon_epoch_fastpath.sh"
run_test "$ROOT/tests/test_timer_daemon_array_inline.sh"
run_test "$ROOT/tests/test_timer_daemon_inline_entry.sh"
run_test "$ROOT/tests/test_timer_batch_snapshot_lock.sh"
run_test "$ROOT/tests/test_timer_format_time_inline.sh"
run_test "$ROOT/tests/test_timer_script_dir_builtin_fastpath.sh"
run_test "$ROOT/tests/test_timer_shift_wheel_adjustment.sh"
run_test "$ROOT/tests/test_timer_set_duration_restarts_interval_accumulates_total.sh"
run_test "$ROOT/tests/test_timer_duration_editor_ui.sh"
run_test "$ROOT/tests/test_weather_secret_storage.sh"
run_test "$ROOT/tests/test_settings_atomic_write.sh"
run_test "$ROOT/tests/test_settings_ui_snapshot_preserves_external_token.sh"
run_test "$ROOT/tests/test_settings_ui_snapshot_preserves_unknown_fields.sh"
run_test "$ROOT/tests/test_settings_ui_save_coalescing.sh"
run_test "$ROOT/tests/test_settings_profile_overlay_file_pruning.sh"
run_test "$ROOT/tests/test_settings_profile_reset_during_pending_write.sh"
run_test "$ROOT/tests/test_settings_writer_completion_signal_race.sh"
run_test "$ROOT/tests/test_settings_ui_snapshot_concurrent_external_token.sh"
run_test "$ROOT/tests/test_settings_mixed_writer_recovery_stress.sh"
run_test "$ROOT/tests/test_settings_corrupt_file_recovery.sh"
run_test "$ROOT/tests/test_settings_backup_tracks_latest_commit.sh"
run_test "$ROOT/tests/test_settings_profile_transaction_crash_recovery.sh"
run_test "$ROOT/tests/test_settings_save_before_initial_load.sh"
run_test "$ROOT/tests/test_timer_alarm_button_primitive.sh"
run_test "$ROOT/tests/test_timer_options_action_button_primitive.sh"
run_test "$ROOT/tests/test_timer_options_action_icon_settings.sh"
run_test "$ROOT/tests/test_timer_random_color_ranges.sh"
run_test "$ROOT/tests/test_timer_manual_color_set.sh"
run_test "$ROOT/tests/test_timer_color_controls_ui.sh"
run_test "$ROOT/tests/test_timer_options_popup_focus_and_comment_input.sh"
run_test "$ROOT/tests/test_timer_options_animation_lifecycle.sh"
run_test "$ROOT/tests/test_timer_options_animation_schema_migration.sh"
run_test "$ROOT/tests/test_timer_options_animation_style_consistency.sh"
run_test "$ROOT/tests/test_timer_options_bidirectional_animation.sh"
run_test "$ROOT/tests/test_timer_options_none_avoids_surface_fade.sh"
run_test "$ROOT/tests/test_timer_options_slide_exit_hides_card.sh"
run_test "$ROOT/tests/test_timer_options_slide_collapse_close.sh"
run_test "$ROOT/tests/test_timer_options_slide_uses_clipped_viewport.sh"
run_test "$ROOT/tests/test_timer_options_symmetric_slide_entry.sh"
run_test "$ROOT/tests/test_calendar_navigation_button_primitive.sh"
run_test "$ROOT/tests/test_calendar_hover_feedback.sh"
run_test "$ROOT/tests/test_calendar_past_days_color.sh"
run_test "$ROOT/tests/test_calendar_past_days_color_morph.sh"
run_test "$ROOT/tests/test_calendar_adjacent_month_days.sh"
run_test "$ROOT/tests/test_calendar_weekend_color_and_marks.sh"
run_test "$ROOT/tests/test_calendar_selected_event_outline.sh"
run_test "$ROOT/tests/test_calendar_explicit_frame_headings.sh"
run_test "$ROOT/tests/test_calendar_note_buttons_shared_primitive.sh"
run_test "$ROOT/tests/test_calendar_note_overlay_morph.sh"
run_test "$ROOT/tests/test_media_controls_shared_button_primitives.sh"
run_test "$ROOT/tests/test_mpv_snapshot_capture.sh"
run_test "$ROOT/tests/test_mpv_snapshot_lookup_inline.sh"
run_test "$ROOT/tests/test_mpv_metadata_batched_parse.sh"
run_test "$ROOT/tests/test_weather_placeholder_shared_button.sh"
run_test "$ROOT/tests/test_weather_placeholder_morph.sh"
run_test "$ROOT/tests/test_weather_cache_fast_path.sh"
run_test "$ROOT/tests/test_weather_cached_poll_process_fastpath.sh"
run_test "$ROOT/tests/test_weather_entrypoint_builtin_assignments.sh"
run_test "$ROOT/tests/test_weather_tempfile_permissions_fastpath.sh"
run_test "$ROOT/tests/test_weather_single_pass_response_validation.sh"
run_test "$ROOT/tests/test_weather_response_size_limit.sh"
run_test "$ROOT/tests/test_weather_endpoint_cache_shape_validation.sh"
run_test "$ROOT/tests/test_weather_single_document_validation.sh"
run_test "$ROOT/tests/test_weather_ttl_environment_validation.sh"
run_test "$ROOT/tests/test_weather_curl_timeout_environment_validation.sh"
run_test "$ROOT/tests/test_weather_attempt_timestamp_validation.sh"
run_test "$ROOT/tests/test_weather_attempt_marker_single_line_validation.sh"
run_test "$ROOT/tests/test_weather_token_not_in_curl_args.sh"
run_test "$ROOT/tests/test_weather_secret_single_document_validation.sh"
run_test "$ROOT/tests/test_weather_script_dir_builtin_fastpath.sh"
run_test "$ROOT/tests/test_weather_stale_cache_fallback.sh"
run_test "$ROOT/tests/test_weather_request_concurrency.sh"
run_test "$ROOT/tests/test_weather_forecast_item_component.sh"
run_test "$ROOT/tests/test_weather_forecast_temperature_validation.sh"
run_test "$ROOT/tests/test_weather_forecast_timestamp_validation.sh"
run_test "$ROOT/tests/test_weather_icon_code_validation.sh"
run_test "$ROOT/tests/test_weather_forecast_live_morph.sh"
run_test "$ROOT/tests/test_weather_hourly_scroll.sh"
run_test "$ROOT/tests/test_weather_hourly_morph.sh"
run_test "$ROOT/tests/test_weather_wind_direction_icons.sh"
run_test "$ROOT/tests/test_weather_font_override.sh"
run_test "$ROOT/tests/test_weather_settings_cleanup.sh"
run_test "$ROOT/tests/test_settings_profile_weather_controls.sh"
run_test "$ROOT/tests/test_weather_explicit_frame_headings.sh"
run_test "$ROOT/tests/test_weather_general_token_refresh_groups.sh"
run_test "$ROOT/tests/test_timer_icons_explicit_frame_heading.sh"
run_test "$ROOT/tests/test_timer_icon_visibility_settings.sh"
run_test "$ROOT/tests/test_timer_icon_morph.sh"
run_test "$ROOT/tests/test_timer_rows_morph.sh"
run_test "$ROOT/tests/test_timer_animation_settings.sh"
run_test "$ROOT/tests/test_timer_button_animation_controls_independent.sh"
run_test "$ROOT/tests/test_timer_elapsed_display_settings.sh"
run_test "$ROOT/tests/test_weather_icon_x_setting.sh"
run_test "$ROOT/tests/test_weather_now_block_layout.sh"
run_test "$ROOT/tests/test_network_stat_row_component.sh"
run_test "$ROOT/tests/test_network_stat_morph_batch.sh"
run_test "$ROOT/tests/test_network_settings_layout_refactor.sh"
run_test "$ROOT/tests/test_networks_selector_popup_link.sh"
run_test "$ROOT/tests/test_networks_compact_content_layout.sh"
run_test "$ROOT/tests/test_network_connection_row_entry_morph.sh"
run_test "$ROOT/tests/test_network_animation_settings.sh"
run_test "$ROOT/tests/test_network_visibility_animation_settings.sh"
run_test "$ROOT/tests/test_cava_animation_settings.sh"
run_test "$ROOT/tests/test_calendar_animation_settings.sh"
run_test "$ROOT/tests/test_cpu_animation_settings.sh"
run_test "$ROOT/tests/test_networks_row_height_binding.sh"
run_test "$ROOT/tests/test_networks_stable_model_exit_morph.sh"
run_test "$ROOT/tests/test_networks_row_transition_completion.sh"
run_test "$ROOT/tests/test_networks_model_owned_exit_progress.sh"
run_test "$ROOT/tests/test_networks_delegate_local_transition_lifecycle.sh"
run_test "$ROOT/tests/test_networks_row_exit_geometry_morph.sh"
run_test "$ROOT/tests/test_networks_connection_layout_morph.sh"
run_test "$ROOT/tests/test_settings_font_field_primitive.sh"
run_test "$ROOT/tests/test_settings_font_fields_migrated.sh"
run_test "$ROOT/tests/test_settings_search_index.sh"
run_test "$ROOT/tests/test_settings_search_ui.sh"
run_test "$ROOT/tests/test_settings_search_controller_extraction.sh"
run_test "$ROOT/tests/test_settings_grouped_navigation.sh"
run_test "$ROOT/tests/test_settings_navigation_items_binding.sh"
run_test "$ROOT/tests/test_settings_navigation_collapsed_persistence.sh"
run_test "$ROOT/tests/test_settings_navigation_notifications_folder_toggle.sh"
run_test "$ROOT/tests/test_settings_last_active_page_persistence.sh"
run_test "$ROOT/tests/test_settings_search_highlight_border_and_mopidy_icons.sh"
run_test "$ROOT/tests/test_settings_search_highlight_primitive.sh"
run_test "$ROOT/tests/test_settings_search_in_place_navigation.sh"
run_test "$ROOT/tests/test_settings_search_match_count_font_size.sh"
run_test "$ROOT/tests/test_settings_search_match_counts.sh"
run_test "$ROOT/tests/test_settings_search_match_cycling.sh"
run_test "$ROOT/tests/test_settings_search_match_hints.sh"
run_test "$ROOT/tests/test_settings_search_breadcrumbs.sh"
run_test "$ROOT/tests/test_notifications_settings_search.sh"
run_test "$ROOT/tests/test_settings_search_no_matches_status.sh"
run_test "$ROOT/tests/test_settings_search_options_group_animation.sh"
run_test "$ROOT/tests/test_settings_search_sidebar_toggle.sh"
run_test "$ROOT/tests/test_system_monitor_volume_parser.sh"
run_test "$ROOT/tests/test_system_monitor_format_bytes.sh"
run_test "$ROOT/tests/test_system_monitor_batch_byte_formatter.sh"
run_test "$ROOT/tests/test_system_monitor_network_connections.sh"
run_test "$ROOT/tests/test_system_monitor_network_connections_inline_status.sh"
run_test "$ROOT/tests/test_system_monitor_network_connections_cache_fast_path.sh"
run_test "$ROOT/tests/test_system_monitor_network_connections_lock_fast_path.sh"
run_test "$ROOT/tests/test_system_monitor_network_stat_baseline.sh"
run_test "$ROOT/tests/test_system_monitor_state_concurrency.sh"
run_test "$ROOT/tests/test_system_monitor_tempfile_chmod_redundancy.sh"
run_test "$ROOT/tests/test_system_monitor_resilient_output.sh"
run_test "$ROOT/tests/test_module_frame_primitive.sh"
run_test "$ROOT/tests/test_settings_schema_audit.sh"
run_test "$ROOT/tests/test_settings_persistence_field_coverage.sh"
run_test "$ROOT/tests/test_settings_contextual_heading.sh"
run_test "$ROOT/tests/test_settings_duplicate_update_intervals.sh"
run_test "$ROOT/tests/test_settings_section_placement.sh"
run_test "$ROOT/tests/test_settings_stable_page_id_routing.sh"
run_test "$ROOT/tests/test_settings_page_registry_catalog.sh"
run_test "$ROOT/tests/test_settings_unified_page_metadata.sh"
run_test "$ROOT/tests/test_settings_search_synonyms.sh"
run_test "$ROOT/tests/test_settings_final_integration.sh"
run_test "$ROOT/tests/test_settings_page_host_extraction.sh"
run_test "$ROOT/tests/test_settings_page_content_extraction.sh"
run_test "$ROOT/tests/test_settings_navigation_controller_extraction.sh"
run_test "$ROOT/tests/test_settings_navigation_component_extraction.sh"
run_test "$ROOT/tests/test_settings_navigation_controller_singleton_scope.sh"
run_test "$ROOT/tests/test_settings_composite_pages_extraction.sh"
run_test "$ROOT/tests/test_settings_calendar_timer_options_weather_refinements.sh"
run_test "$ROOT/tests/test_settings_profiles_reset_all_visibility_and_weather_comfort_single_y.sh"
run_test "$ROOT/tests/test_settings_frame_consistency.sh"
run_test "$ROOT/tests/test_settings_modules_themes_framed_headings.sh"
run_test "$ROOT/tests/test_settings_group_fieldset_legend.sh"
run_test "$ROOT/tests/test_settings_concise_headings.sh"
run_test "$ROOT/tests/test_profiles_general_subtab.sh"
run_test "$ROOT/tests/test_settings_label_spacing_and_timer_icon_arrows.sh"
run_test "$ROOT/tests/test_settings_input_label_vertical_alignment.sh"
run_test "$ROOT/tests/test_mopidy_time_settings_duplicates.sh"
run_test "$ROOT/tests/test_mopidy_explicit_frame_headings.sh"
run_test "$ROOT/tests/test_mopidy_animation_settings.sh"
run_test "$ROOT/tests/test_mopidy_morph_expansions_batch.sh"
run_test "$ROOT/tests/test_mopidy_top_panel_optional_metadata_morph.sh"
run_test "$ROOT/tests/test_mopidy_queue_optional_controls_morph_batch.sh"
run_test "$ROOT/tests/test_sparse_profiles.sh"
run_test "$ROOT/tests/test_profile_overlay_storage_format.sh"
run_test "$ROOT/tests/test_color_preferences_survive_default_changes.sh"
run_test "$ROOT/tests/test_legacy_profile_defaults_migration.sh"
run_test "$ROOT/tests/test_legacy_settings_version_matrix.sh"
run_test "$ROOT/tests/test_settings_schema_input_shapes_and_reserved_keys.sh"
run_test "$ROOT/tests/test_profiles_theme_reference_lifecycle.sh"
run_test "$ROOT/tests/test_profiles_theme_repeated_lifecycle.sh"
run_test "$ROOT/tests/test_custom_theme_color_migration.sh"
run_test "$ROOT/tests/test_theme_palette_roundtrip_canonicalization.sh"
run_test "$ROOT/tests/test_theme_management_guardrails.sh"
run_test "$ROOT/tests/test_theme_switch_preserves_independent_component_colors.sh"
run_test "$ROOT/tests/test_theme_independent_colors_are_not_palette_state.sh"
run_test "$ROOT/tests/test_mpris_artwork_download_reliability.sh"
run_test "$ROOT/tests/test_mpris_artwork_cache_hit_skip_mkdir.sh"
run_test "$ROOT/tests/test_mpris_artwork_player_selection.sh"
run_test "$ROOT/tests/test_mpris_metadata_string_preservation.sh"
run_test "$ROOT/tests/test_player_json_serialization_builtin.sh"
run_test "$ROOT/tests/test_mpris_player_list_cache.sh"
run_test "$ROOT/tests/test_jitsi_browser_title_fallback.sh"
run_test "$ROOT/tests/test_jitsi_active_call_priority.sh"
run_test "$ROOT/tests/test_mpris_browser_metadata_prefetch_reuse.sh"
run_test "$ROOT/tests/test_launcher_cross_search_and_pass_enter.sh"
run_test "$ROOT/tests/test_launcher_missing_icon_fallback.sh"
run_test "$ROOT/tests/test_player_animation_settings.sh"
run_test "$ROOT/tests/test_player_next_button_morph.sh"
run_test "$ROOT/tests/test_player_progress_settings_placement.sh"
run_test "$ROOT/tests/test_player_progress_morph.sh"
run_test "$ROOT/tests/test_player_progress_live_morph.sh"
run_test "$ROOT/tests/test_player_text_outline_color_morph.sh"
run_test "$ROOT/tests/test_player_metadata_live_morph.sh"
run_test "$ROOT/tests/test_weather_animation_settings.sh"
run_test "$ROOT/tests/test_weather_comfort_outline.sh"
run_test "$ROOT/tests/test_weather_comfort_live_morph.sh"
run_test "$ROOT/tests/test_weather_now_live_data_morph.sh"
run_test "$ROOT/tests/test_weather_comfort_outline_settings.sh"
run_test "$ROOT/tests/test_settings_theme_expanded_list.sh"
run_test "$ROOT/tests/test_settings_weather_wind_direction_morph.sh"
run_test "$ROOT/tests/test_deadbeef_backend_regression.sh"
run_test "$ROOT/tests/test_player_backend_fallback_on_invalid_deadbeef.sh"
run_test "$ROOT/tests/test_player_backend_fallback_on_invalid_metadata.sh"
run_test "$ROOT/tests/test_clock_settings_integration.sh"
run_test "$ROOT/tests/test_settings_profile_scoped_save.sh"
run_test "$ROOT/tests/test_settings_profile_scoped_save_ui.sh"
run_test "$ROOT/tests/test_settings_profile_controller_extraction.sh"
run_test "$ROOT/tests/test_timer_options_reset_restores_popup_animation.sh"
run_test "$ROOT/tests/test_timer_random_color_custom_morph.sh"
run_test "$ROOT/tests/test_timer_finished_image_options_morph.sh"
run_test "$ROOT/tests/test_settings_timer_weather_color_choice_morph_batch.sh"
run_test "$ROOT/tests/test_settings_theme_editor_morph_batch.sh"
run_test "$ROOT/tests/test_notifications_server_stage1.sh"

run_test "$ROOT/tests/test_launcher_special_app_search.sh"
run_test "$ROOT/tests/test_launcher_app_categories.sh"
run_test "$ROOT/tests/test_launcher_app_preferences.sh"
run_test "$ROOT/tests/test_launcher_fuzzy_search_setting.sh"
run_test "$ROOT/tests/test_launcher_keyboard_layout_search.sh"
run_test "$ROOT/tests/test_launcher_app_catalog_refresh.sh"
run_test "$ROOT/tests/test_launcher_fuzzy_actions_setting.sh"
run_test "$ROOT/tests/test_launcher_fuzzy_schemes_wallpapers_setting.sh"
run_test "$ROOT/tests/test_launcher_fuzzy_search_subtab.sh"
run_test "$ROOT/tests/test_launcher_builtin_action_subtabs.sh"
run_test "$ROOT/tests/test_launcher_page_dirty_scope.sh"
run_test "$ROOT/tests/test_dashboard_overview_panel.sh"
run_test "$ROOT/tests/test_dashboard_visibility_animation.sh"
run_test "$ROOT/tests/test_dashboard_corner_settings_button.sh"
run_test "$ROOT/tests/test_dashboard_modules_toggle.sh"
run_test "$ROOT/tests/test_dashboard_module_geometry_surface.sh"
run_test "$ROOT/tests/test_dashboard_qml_unique_properties.sh"
run_test "$ROOT/tests/test_dashboard_settings_button_focus.sh"
run_test "$ROOT/tests/test_dashboard_smart_editing.sh"
run_test "$ROOT/tests/test_dashboard_smart_layout_edit.sh"
run_test "$ROOT/tests/test_dashboard_shared_geometry.sh"
run_test "$ROOT/tests/test_dashboard_external_spacing_scrollbar.sh"
run_test "$ROOT/tests/test_dashboard_keyboard_navigation_scroll.sh"
run_test "$ROOT/tests/test_dashboard_passive_cards.sh"
run_test "$ROOT/tests/test_dashboard_launcher_entry.sh"
run_test "$ROOT/tests/test_dashboard_independent_cards.sh"
run_test "$ROOT/tests/test_dashboard_columns_setting.sh"
run_test "$ROOT/tests/test_dashboard_card_sizes.sh"
run_test "$ROOT/tests/test_dashboard_responsive_width_audit.sh"
run_test "$ROOT/tests/test_dashboard_today_card.sh"
run_test "$ROOT/tests/test_dashboard_notifications_dnd.sh"
run_test "$ROOT/tests/test_dashboard_wide_network_balance.sh"
run_test "$ROOT/tests/test_dashboard_wide_weather_balance.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_composition.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_system_details.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_system_top_app_value.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_network_details.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_media_artwork.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_media_playback_state.sh"
run_test "$ROOT/tests/test_dashboard_media_remaining_time_validation.sh"
run_test "$ROOT/tests/test_dashboard_wide_compact_weather_icon_fallback.sh"
run_test "$ROOT/tests/test_dashboard_expanded_weather_icon_fallback.sh"
run_test "$ROOT/tests/test_dashboard_weather_wind_speed_validation.sh"
run_test "$ROOT/tests/test_dashboard_weather_wind_direction_validation.sh"
run_test "$ROOT/tests/test_weather_now_wind_metadata_validation.sh"
run_test "$ROOT/tests/test_weather_pressure_metadata_validation.sh"
run_test "$ROOT/tests/test_weather_temperature_metadata_validation.sh"
run_test "$ROOT/tests/test_dashboard_release_integration.sh"

# Settings navigation redesign baseline and agreed interaction contract.
run_test "$ROOT/tests/test_settings_navigation_redesign_audit.sh"
run_test "$ROOT/tests/test_settings_navigation_folder_primitive.sh"
run_test "$ROOT/tests/test_settings_navigation_folder_card.sh"
run_test "$ROOT/tests/test_settings_navigation_folder_surface_animation_bounds.sh"
run_test "$ROOT/tests/test_settings_navigation_order_hierarchy.sh"
run_test "$ROOT/tests/test_settings_flat_order_migration_cleanup.sh"
run_test "$ROOT/tests/test_settings_navigation_group_frame_order_ui.sh"
run_test "$ROOT/tests/test_settings_navigation_page_order_by_group.sh"
run_test "$ROOT/tests/test_settings_navigation_framed_page_editor.sh"
run_test "$ROOT/tests/test_settings_navigation_editor_visual_polish.sh"
run_test "$ROOT/tests/test_settings_collapsed_active_page_indicator.sh"
run_test "$ROOT/tests/test_settings_navigation_active_state_semantics.sh"
run_test "$ROOT/tests/test_settings_navigation_keyboard_accessibility.sh"
run_test "$ROOT/tests/test_settings_focus_restore_page_transitions.sh"
run_test "$ROOT/tests/test_settings_navigation_final_integration.sh"
run_test "$ROOT/tests/test_settings_narrow_window_navigation.sh"

# Report a registration/runner mismatch only after every scheduled invocation.
if ((CHECK_CURRENT != CHECK_TOTAL)); then
    CHECK_STEP_TOTAL=$((CHECK_STEP_TOTAL + 1))
    CHECK_STEP_FAILED=$((CHECK_STEP_FAILED + 1))
    CHECK_FAILED_STEP_NAMES+=("CHECK runner count mismatch: ran $CHECK_CURRENT of $CHECK_TOTAL registered tests")
    printf '\nCHECK runner count mismatch: ran %s of %s registered tests\n' "$CHECK_CURRENT" "$CHECK_TOTAL" >&2
fi

# Do not stop early: preserve the complete diagnostics and fail the overall run at the end.
if ((CHECK_FAILED > 0 || CHECK_STEP_FAILED > 0)); then
    exit 1
fi
