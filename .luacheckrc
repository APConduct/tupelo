-- Simple Luacheck configuration for Tupelo
std = "lua54"

ignore = {
    "212", -- Unused argument (common in functional programming)
    "213"  -- Unused loop variable
}
