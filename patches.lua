-- patch definitions

--[[
if (not Debian) then
	print("launch from main()!")
	os.exit(-1)
end
]]

patches_def = {

{ title = "APT: no recommends and suggests",
	{	op = "addlines",
		path = "/etc/apt/apt.conf",		-- doesn't exist on new system
		args = 
		{	'APT::Install-Recommends "false";',
			'APT::Install-Suggests "false";',
		},
	},
},

{ title = "APT: no sources",
	{	op = "gsublines",
		path = "/etc/apt/sources.list",
		args =
		{	{"\n(deb%-src.-)\n", "\n# %1\n"},
		},
	},
},

{ title = "kernel: disable IPv6",
	{	op = "addlines",
		path = "/etc/sysctl.conf",
		args =
		{	"net.ipv6.conf.default.disable_ipv6 = 1",
			"net.ipv6.conf.all.disable_ipv6 = 1",
		--	"net.ipv6.conf.lo.disable_ipv6 = 1",		-- was missing before
			"net.ipv6.conf.eth0.disable_ipv6 = 1",
		},
	},
},

{ title = "root .bashrc",
	{	op = "addlines",
		path = "/root/.bashrc",
		args = {"HISTFILE=/dev/null"},
	},
},

{ title = "user .profile BASE",
	{	op = "addlines",
		path = "$LSK/.profile",
		args = {[[
PATH="/sbin:$PATH"

# color man
export MANPAGER=/usr/bin/most

# disable screensaver
xset -dpms
xset s noblank
xset s off

if [ "$DISPLAY" != "" ]; then
  setxkbmap -option -model microsoft4000 -layout us,us -variant euro,intl -option grp:win_switch -option altwin:ctrl_alt_win
  xset -display :0 r rate 660 75
fi
]]
		},
	},
},

{ title = "user .profile DEV",
	{	op = "addlines",
		path = "$LSK/.profile",
		args =
		{	'export LXDEV=/media/dev',
			'export P4_WORKSPACE="$LXDEV/vlc_depot"',
			'export WXCONFIG_LUA="$P4_WORKSPACE/DebLua/wxconfig.lua"',
			'export LXBUILD="$LXDEV/build"',
			'export LXGIT="$LXDEV/git"',
			'',
		},
	},
},

{ title = "user .bashrc",
	{	op = "gsublines",
		path = "$LSK/.bashrc",
		args =
		{	{"#(force_color_prompt=yes)", "%1"},
			{"^(.+)$", "%1\nHISTFILE=/dev/null\n"},		-- add to end (captures all then appends)
		},
	},
},

{ title = "user .nanorc",
	{	op = "addlines",
		path = "$LSK/.nanorc",
		nmatch = "set mouse",
		args =
		{	[[	set mouse
				set softwrap
				]]
		},
	},
},

{ title = "link clang 3.5 binaries",
	{	op = "exec",
		path = "/usr/bin",
		args =
		{
			"ln -s /usr/bin/clang-3.5 /usr/bin/clang",
			"ln -s /usr/bin/clang++-3.5 /usr/bin/clang++",
			"ln -s /usr/bin/lldb-3.5 /usr/bin/lldb"
		},
	}
},

{ title = "link clang 3.7/8 binaries",
	{	op = "exec",
		path = "/usr/bin",
		args =
		{
			"ln -s /usr/bin/clang-3.5 /usr/bin/clang",
			"update-alternatives --install /usr/bin/lldb-server lldb-server /usr/bin/lldb-server-3.7 100",
			"update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-3.7 100"
		},
	}
},

{ title = "get Perforce client",
	{	op = "exec",
		path = "/usr/local",
		args =
		{
			"wget ftp.perforce.com/perforce/r14.3/bin.linux26x86_64/p4v.tgz",
		},
	}
},

{ title = "link p4v",
	{	op = "exec",
		path = "/usr/local/bin",
		args =
		{
			"ln -s /usr/local/lib/p4v/P4VResources P4VResources",
		},
	}
},

{ title = "gen wx-config wrapper",
	{	op = "exec",
		path = "/usr/local/games",
		args =
		{
			"echo -e '#!/bin/sh\ncfg=\"$WXDIR/wx-config\"\n$cfg $@\n' > wx-config",
			"chmod +x wx-config"
		},
	}
},

{ title = "SLiM: auto-login",
	{	op = "gsublines",
		path = "/etc/slim.conf",
		args =
		{	-- {"#(default_user%s+)simone", "%1"..Debian.USER},
			{"#(default_user%s+)simone", "%1".."lsk"},		-- HARDCODED USER
			{"#(auto_login%s+)no", "%1yes"},
		},
	},
},

{ title = "link Documents",
	{	op = "exec",
		path = "$LSK/.local/share/notes",
		args =
		{
			"ln -s /home/$LSK/Documents/notes/Notes /home/$LSK/.local/share/notes/Notes",
			"ln -s /home/$LSK/Documents/abook /home/$LSK/.abook"
		},
	}
},

{ title = "X11 qemu",
	{
		op = "addlines",
		path = "/etc/X11/xorg.conf",
		args =
		{	"", [[
Section "Monitor"
  Identifier  "Monitor0"
  HorizSync   20.0 - 50.0
  VertRefresh 40.0 - 80.0
EndSection

Section "Device"
  Identifier "Device0"
  Driver     "vesa"
EndSection

Section "Screen"
  Identifier   "Screen0"
  Device       "Device0"
  Monitor      "Monitor0"
  DefaultDepth 24
  Subsection "Display"
    Depth 24
#    Modes "1280x1024"
#    Modes "1440x900"
    Modes "1440x1024"
  EndSubsection
EndSection
]], ""

		},
	},
},

}

---- Xfce4 Configuration Definitions -------------------------------------------

xfce4_def =
{
	["Appearance"] =
	{
		{"xfwm4",			"/general/theme",				"Agualemon"},
		{"xfwm4",			"/general/button_layout",			"O|HMC"},
		{"xsettings",			"/Net/ThemeName",				"Xfce-cadmium"},
		{"xsettings",			"/Xft/Antialias",				1},
		{"xsettings",			"/Xft/HintStyle",				"hintfull"},
		{"xfce4-desktop",		"/desktop-icons/file-icons/show-home",		false},
		{"xfce4-desktop",		"/desktop-icons/file-icons/show-trash",		false},
		{"xfce4-desktop",		"/backdrop/screen0/monitor0/color-style",	2},
		{"xfce4-desktop",		"/backdrop/screen0/monitor0/image-show",	false},
		{"xfce4-desktop",		"/backdrop/screen0/monitor0/color1",		{"2570u", "49884u", "45891u", "65535u"}},
		{"xfce4-desktop",		"/backdrop/screen0/monitor0/color2",		{"23900u", "30583u", "45875u", "65535u"}},
		-- {"xfwm4",			"/general/use_compositing",			true},
	},

	["Panels"] =
	{
		{"xfce4-panel",			"/plugins/plugin-1/button-title",		"Menu"},
		{"xfwm4",			"/general/toggle_workspaces",			false},
		{"xfwm4",			"/general/workspace_count",			1},
	},
	
	["keyboard"] =
	{
		{"keyboards",			"/Default/KeyRepeat/Rate",			70},					-- must be created if doesn't exist
		{"xfce4-keyboard-shortcuts",	"/commands/custom/F1",				"xfce4-terminal"},
		{"xfce4-keyboard-shortcuts",	"/commands/custom/<Shift>F1",			"xfce4-terminal -e 'sudo -i'"},
		{"xfwm4",			"/general/mousewheel_rollup",			false},					-- disable window roll-up
	},
	
	-- only on JESSIE?
	["Thunar view"] =
	{
		{"thunar",			"/default-view",				"ThunarDetailsView"},
		{"thunar",			"/last-view",					"ThunarDetailsView"},
		{"thunar",			"/misc-thumbnail-mode",				"THUNAR_THUMBNAIL_MODE_NEVER"},
		{"thunar",			"/misc-date-style",				"THUNAR_DATE_STYLE_ISO"},
	},
}

xfce4_def_list = {"Appearance", "Panels", "keyboard", "Thunar view"}

