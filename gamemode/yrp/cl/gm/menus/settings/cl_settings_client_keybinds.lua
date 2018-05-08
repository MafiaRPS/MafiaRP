--Copyright (C) 2017-2018 Arno Zura ( https://www.gnu.org/licenses/gpl.txt )

function createDKeybinder( parent, w, h, x, y, keybind )
  local _tmp = createD( "DBinder", parent, w, h, x, y )
  _tmp:SetValue( get_keybind( keybind ) )
  function _tmp:OnChange( num )
    set_keybind( keybind, num )
  end
  function _tmp:Paint( pw, ph )
    paintButton( self, pw, ph, "" )
  end
  return _tmp
end

hook.Add( "open_client_keybinds", "open_client_keybinds", function()
  SaveLastSite()
  local ply = LocalPlayer()
  local w = settingsWindow.window.sitepanel:GetWide()
  local h = settingsWindow.window.sitepanel:GetTall()

  local _wide = 800

  settingsWindow.window.site = createD( "DPanel", settingsWindow.window.sitepanel, w, h, 0, 0 )
  --sheet:AddSheet( lang_string( "character" ), cl_charPanel, "icon16/user_edit.png" )
  function settingsWindow.window.site:Paint( w, h )
    --draw.RoundedBox( 0, 0, 0, sv_generalPanel:GetWide(), sv_generalPanel:GetTall(), _yrp.colors.panel )
    draw.SimpleTextOutlined( lang_string("characterselection"), "sef", ctr( _wide ), ctr( 60 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("rolemenu"), "sef", ctr( _wide ), ctr( 120 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("buymenu"), "sef", ctr( _wide ), ctr( 180 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("settings"), "sef", ctr( _wide ), ctr( 240 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("guimouse"), "sef", ctr( _wide ), ctr( 300 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("map"), "sef", ctr( _wide ), ctr( 360 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("inventory"), "sef", ctr( _wide ), ctr( 420 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("vehicles") .. " (" .. lang_string("settings") .. ")", "sef", ctr( _wide ), ctr( 480 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("doors") .. " (" .. lang_string("settings") .. ")", "sef", ctr( _wide ), ctr( 540 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("voicenext"), "sef", ctr( _wide ), ctr( 600 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("voiceprev"), "sef", ctr( _wide ), ctr( 660 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("viewzoomout"), "sef", ctr( _wide ), ctr( 720 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("viewzoomin"), "sef", ctr( _wide ), ctr( 780 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("drop"), "sef", ctr( _wide ), ctr( 840 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("weaponlowering"), "sef", ctr( _wide ), ctr( 900 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("appearance"), "sef", ctr( _wide ), ctr( 960 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("emotes"), "sef", ctr( _wide ), ctr( 1020 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )

    draw.SimpleTextOutlined( lang_string("viewswitch"), "sef", ctr( _wide ), ctr( 1080 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("incviewheight"), "sef", ctr( _wide ), ctr( 1140 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("decviewheight"), "sef", ctr( _wide ), ctr( 1200 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("viewposright"), "sef", ctr( _wide ), ctr( 1260 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("viewposleft"), "sef", ctr( _wide ), ctr( 1320 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("turnviewangleright"), "sef", ctr( _wide ), ctr( 1380 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("turnviewangleleft"), "sef", ctr( _wide ), ctr( 1440 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )

    draw.SimpleTextOutlined( lang_string("opensmartphone"), "sef", ctr( _wide ), ctr( 1500 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
    draw.SimpleTextOutlined( lang_string("closesmartphone"), "sef", ctr( _wide ), ctr( 1560 ), Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, Color( 0, 0, 0 ) )
end

  local _k = {}
  _k._cs = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 60 ), "menu_character_selection" )
  _k._mr = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 120 ), "menu_role" )
  _k._mb = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 180 ), "menu_buy" )
  _k._ms = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 240 ), "menu_settings" )
  _k._tm = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 300 ), "toggle_mouse" )
  _k._tm = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 360 ), "toggle_map" )
  _k._mi = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 420 ), "menu_inventory" )
  _k._mv = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 480 ), "menu_options_vehicle" )
  _k._md = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 540 ), "menu_options_door" )
  _k._sgr = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 600 ), "speak_next" )
  _k._sgl = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 660 ), "speak_prev" )
  _k._vzo = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 720 ), "view_zoom_out" )
  _k._vzi = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 780 ), "view_zoom_in" )
  _k._di = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 840 ), "drop_item" )
  _k._wl = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 900 ), "weaponlowering" )
  _k._ap = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 960 ), "menu_appearance" )
  _k._me = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1020 ), "menu_emotes" )

  _k._vs = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1080 ), "view_switch" )
  _k._vu = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1140 ), "view_up" )
  _k._vd = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1200 ), "view_down" )
  _k._vr = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1260 ), "view_right" )
  _k._vl = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1320 ), "view_left" )
  _k._vsr = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1380 ), "view_spin_right" )
  _k._vsl = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1440 ), "view_spin_left" )

  _k._osp = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1500 ), "sp_open" )
  _k._csp = createDKeybinder( settingsWindow.window.site, ctr( 400 ), ctr( 50 ), ctr( _wide+10 ), ctr( 1560 ), "sp_close" )
end)
