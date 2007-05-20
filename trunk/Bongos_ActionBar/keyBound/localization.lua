--[[
	KeyBound localization file
		English (default)
--]]

KEYBOUND_LOCALS = {}

local L = KEYBOUND_LOCALS
L.Enabled = "Bindings mode enabled"
L.Disabled = "Bindings mode disabled"
L.ClearTip = format("Press %s to clear all bindings", GetBindingText("ESCAPE", "KEY_"))
L.NoKeysBoundTip = "No current bindings"
L.ClearedBindings = "Removed all bindings from %s"
L.BoundKey = "Set %s to %s"
L.UnboundKey = "Unbound %s from %s"
L.CannotBindInCombat = "Cannot bind keys in combat"
L.CombatBindingsEnabled = "Exiting combat, keybinding mode enabled"
L.CombatBindingsDisabled = "Entering combat, keybinding mode disabled"