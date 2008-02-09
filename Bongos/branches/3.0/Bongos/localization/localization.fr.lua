--[[
	Bongos' Localization File
		French Language
		
	ANSI Formatted
--]]

local L = LibStub("AceLocale-3.0"):NewLocale("Bongos3", "frFR")
if not L then return end

--system messages
L.NewPlayer = "Nouveau profil créé pour %s"
L.Updated = "MAJ à v%s"
L.UpdatedIncompatible = "Mise à jour depuis une version incompatible. Paramètres par défaut chargé"

--profiles
L.ProfileCreated = "Nouveau profil créé \"%s\""
L.ProfileLoaded = "Définir profil a \"%s\""
L.ProfileDeleted = "Supprimer profil \"%s\""
L.ProfileCopied = "Copié les paramètres depuis \"%s\""
L.ProfileReset = "Remettre à zéro le profil \"%s\""
L.CantDeleteCurrentProfile = "Le profil courant ne peut être supprimé"

--slash command help
L.ShowOptionsDesc = "Montrer le menu options"
L.LockBarsDesc = "Activé/Désactivé le verrouillage de la position des barres"
L.StickyBarsDesc = "Activé/Désactivé ancrage automatique des barres"

L.SetScaleDesc = "Définit l'échelle de <barList>"
L.SetAlphaDesc = "Définit l'opacité de <barList>"

L.ShowBarsDesc = "Affiche <barList>"
L.HideBarsDesc = "Cache <barList>"
L.ToggleBarsDesc = "Affiche/Cache <barList>"

--slash commands for profiles
L.SetDesc = "Changé les paramètres <profile>"
L.SaveDesc = "Sauve les paramètres courants et change les paramètres vers <profile>"
L.CopyDesc = "Copier les paramètres depuis <profile>"
L.DeleteDesc = "Supprimer <profile>"
L.ResetDesc = "Revenir aux paramètres par défaut"
L.ListDesc = "Lister tous les profiles"
L.AvailableProfiles = "Profiles disponibles"
L.PrintVersionDesc = "Afficher la version courante de Bongos"

--dragFrame tooltips
L.ShowConfig = "<Click Droit> pour configurer"
L.HideBar = "<Click Milieu or Shift Click Droit> pour cacher"
L.ShowBar = "<Click Milieu or Shift Click Droit> pour afficher"
L.SetAlpha = "<Molette> pour définir l'opacité (|cffffffff%d|r)"

--Menu Stuff
L.Scale = "Echelle"
L.Opacity = "Opacité"
L.FadedOpacity = "AutoFade Opacity"
L.Visibility = "Visibilité"
L.Spacing = "Espacement"
L.Layout = "Disposition"

--minimap button stuff
L.ShowMenuTip = "<Click Droit> pour afficher le menu des options"
L.HideMenuTip = "<Click Droit> pour cacher le menu des options"
L.LockBarsTip = "<Click Gauche> pour verrouiller la position des barres"
L.UnlockBarsTip = "<Click Gauche> to déverrouiller la position des barres"
L.LockButtonsTip = "<Shift Click Gauche> pour verrouiller la position des boutons"
L.UnlockButtonsTip = "<Shift Click Gauche> pour déverrouiller la position des bouttons"