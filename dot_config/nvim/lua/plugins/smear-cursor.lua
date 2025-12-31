return {
    -- Disabled for now in favour of testing Kitty's native cursor trail.
    enabled = false,
    "sphamba/smear-cursor.nvim",
    opts = {
        cursor_color = "#f83d19",
        stiffness = 0.8,
        trailing_stiffness = 0.6,
        distance_stop_animating = 0.5,
        legacy_computing_symbols_support = true,

        smear_insert_mode = true,
        legacy_computing_symbols_support_vertical_bars = true,
        distance_stop_animating_vertical_bar = 0.1,
    },
}
