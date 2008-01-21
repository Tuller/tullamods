--[[
	Bongos' Localization File
	Spanish by Ferroginu from Zul'jin
	¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡ SAVE in UTF-8 !!!!!!!!!!!!!!!!!!!!!!!!
--]]

if GetLocale() ~= 'esES' then return end

local L = BONGOS_LOCALS

--system messages
L.NewPlayer = "Creado perfil nuevo para %s"
L.Updated = "Actualizado a v%s"
L.UpdatedIncompatible = "Actualizando de una versión incompatible. Cargando valores predeterminados."

--profiles
L.ProfileCreated = "Creado nuevo perfil \"%s\""
L.ProfileLoaded = "Perfil activado \"%s\""
L.ProfileDeleted = "Borrado perfil \"%s\""
L.ProfileCopied = "Perfil copiado de \"%s\" a \"%s\""
L.ProfileReset = "Perfil reinicializado \"%s\""
L.CantDeleteCurrentProfile = "No se puede borrar el perfil activo"

--slash command help
L.ShowOptionsDesc = "Mostrar el menú de opciones"
L.LockBarsDesc = "Des/Acivar bloqueo de las barras"
L.StickyBarsDesc = "Des/Acivar auto-anclaje de las barras"

L.SetScaleDesc = "Escala de la barra <barList>"
L.SetAlphaDesc = "Opacidad de la barra <barList>"

L.ShowBarsDesc = "Mostrar la barra <barList>"
L.HideBarsDesc = "Esconder la barra <barList>"
L.ToggleBarsDesc = "Des/Activar la barra <barList>"

--slash commands for profiles
L.SetDesc = "Cambia los valores a <profile>"
L.SaveDesc = "Guarda los valores actuales y cambia a <profile>"
L.CopyDesc = "Copia los valores de <profile>"
L.DeleteDesc = "Borra <profile>"
L.ResetDesc = "Vuelve a los valores predeterminados"
L.ListDesc = "Lista todos los perfiles"
L.AvailableProfiles = "Perfiles disponibles"
L.PrintVersionDesc = "Muestra la versión actual de Bongos"

--dragFrame tooltips
L.ShowConfig = "<Botón DER> para configurar"
L.HideBar = "<Botón CENTRAL o MAY+Botón DER> para esconder"
L.ShowBar = "<Botón CENTRAL o MAY+Botón DER> para mostrar"
L.SetAlpha = "<Rueda del Ratón> nivel de opacidad (|cffffffff%d|r)"

--Menu Stuff
L.Scale = "Escala"
L.Opacity = "Opacidad"
L.FadedOpacity = "Auto-fundido Opacidad"
L.Visibility = "Visibilidad"
L.Spacing = "Espaciado"
L.Layout = "Diseño"

--minimap button stuff
L.ShowMenuTip = "<Botón DER> para mostrar el menú de opciones"
L.HideMenuTip = "<Botón DER> para esconder el menú de opciones"
L.LockBarsTip = "<Botón IZQ> para bloquear las barras"
L.UnlockBarsTip = "<Botón IZQ> para desbloquear las barras"
L.LockButtonsTip = "<MAY+Botón IZQ> para bloquear los botones"
L.UnlockButtonsTip = "<MAY+Botón IZQ> para desbloquear los botones"