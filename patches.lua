-- patch definitions

--[[
if (not Debian) then
	print("launch from main()!")
	os.exit(-1)
end
]]

--[[ TO DO
#wire terminal keys
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/F1 -s 'xfce4-terminal'
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Shift>F1 -n /commands/custom/<Shift>F1 -t string -s "xfce4-terminal -e 'sudo -i'"

remove deb-src entries

]]

patches_def = {

{ title = "APT: no recommends and suggests",
	{	op = "addlines",
		path = "/etc/apt/apt.conf",		-- doesn't exist on new system
		nmatch = 'APT::Install',
		args = 
		{	'APT::Install-Recommends "false";',
			'APT::Install-Suggests "false";',
		},
	},
},

--[[
{ title = "APT: proxy",
	{	op = "addlines",
		path = "/etc/apt/apt.conf",
		nmatch = 'Acquire::http::Proxy',
		args =
		{	'Acquire::http::Proxy "http://192.168.1.4:3142/";',
		},
	},
},]]

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

--[[
ignored on Jessie/systemd, instead use:
 systemctl enable tmp.mount
]]
{ title = "memory rcS",
	{	op = "addlines",
		path = "/etc/default/rcS",				-- should now be in /etc/default/tmpfs !
		args = {"RAMRUN=YES", "RAMLOCK=YES", "TMPTIME=0"},
		-- RAMSHM, RAMTMP ?
	},
},
--[[
or add to /etc/fstab
 tmpfs	/tmp/tmpfs	tmpfs	nodev,nosuid,mode=1777,strictatime	0 0
]]

{ title = "root .bashrc",
	{	op = "addlines",
		path = "/root/.bashrc",
		args = {"HISTFILE=/dev/null"},
	},
},

{ title = "user .profile BASE",
	{	op = "addlines",
		path = "$LSK/.profile",
		nmatch = 'export MANPAGER',
		args =
		{	'PATH="/sbin:$PATH"',
			'',
			'# color man', 'export MANPAGER=/usr/bin/most',
			'',
			'# screensaver', 'xset -dpms', 'xset s noblank', 'xset s off',
			'',
		},
	},
},

{ title = "user .profile DEV",
	{	op = "gsublines",
		path = "$LSK/.profile",
		nmatch = 'export DEVELOPMENT',
		args =
		{	'export DEVELOPMENT="$HOME/development"',
			'export P4_WORKSPACE="$DEVELOPMENT/inhance_depot"',
			'export WXCONFIG_LUA="$P4_WORKSPACE/DebLua/wxconfig.lua"',
			'',
			'export LXDEV="$HOME/development"',
			'export LXBUILD="$HOME/development/build"',
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

--[=[

{ title = "X11: qemu vostro430",
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
     Modes "1440x900"
#    Modes "1440x1024"
  EndSubsection
EndSection
]]
		},
	},
},

]=]

--[[

========================

 op = "addlines",
 path = "/etc/hosts"
 args = 
 {	"192.168.1.4	debnas",
 }
 
================================

 #Perforce
export P4PORT=debnas:1666
export P4USER=peterl


{ title = "UFW: disable IPv6",
	{	op = "gsublines",
		path = "/etc/default/ufw",
		args =
		{	{'\nIPV6=yes\n', '\nIPV6=no\n'},
		},
	},
		
	{	op = "gsublines",
		path = "/etc/ufw/sysctl.conf",
		args =
		{	{'(net/ipv6/conf/default/autoconf)=1', '%1=0'},
			{'(net/ipv6/conf/all/autoconf=)1', '%10'},		-- try!
		},
	},
},

{ title = "SSH server: no DNS lookup",
	{	op = "gsublines",
		path = "/etc/ssh/sshd_config",
		args =
		{	{"(Protocol%s+2\n)", "%1UseDNS no\n"},			-- no DNS is CRITICAL to be able to work offline!
			{"PermitRootLogin(.+)\n", " no"},
			{"X11Forwarding(.+)\n", " no"},
			{"#(IgnoreUserKnownHosts%s+yes\n)", "%1"},
			-- PrintLastLog no
		},
	},
},

{ title = "network config 192.168.1.7",
	{	op = "addlines",
		path = "/etc/network/interfaces",
		args =
		{	"# This file describes the network interfaces available on your system",
			"# and how to activate them. For more information, see interfaces(5).",
			"# The loopback network interface",
			"auto lo",
			"iface lo inet loopback",
			"",
			"# The primary network interface",
			"allow-hotplug eth0",
			"iface eth0 inet static",
			"	address 192.168.1.7",
			"	netmask 255.255.255.0",
			"	network 192.168.1.0",
			"	broadcast 192.168.1.255",
			"	gateway 192.168.1.1",
			"	# dns-* options are implemented by the resolvconf package, if installed",
			"	dns-nameservers 87.216.1.86 87.216.1.66",
			-- {"	dns-search theloft.dj"},
		},
	},
},

{ title = "SSD fstab",
	{	op = "addlines",
		path = "/etc/fstab",
		args =
		{	"none	/tmp		tmpfs	defaults,noatime,mode=1777					0	0",
			"none	/var/log	tmpfs	defaults,noatime,uid=0,gid=4,mode=2775		0	0",
			"none	/var/spool	tmpfs	defaults,noatime,uid=0,gid=102,mode=2775	0	0",
			"none	/var/local	tmpfs	defaults,noatime,uid=0,gid=50,mode=2775		0	0",
			--		rsyslog needs
			--			/var/spool/rsyslog	root:adm

		},
	},
				
	-- SSD TRIM
	{	op = "gsublines",
		path = "/etc/fstab",
		args =
		{	{"(%s/%s+ext4%s+(noatime,)?errors=remount-ro)", "%1,discard"},
		},
	},				
},
]]

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

--[[	
	["test"] =
	{
		{"xfce4-desktop",		"/backdrop/screen0/monitor0/color1",		{"0u", "65535u", "0u", "65535u"}},
	},

	["reset"] =
	{
		{"xfce4-desktop",		"/backdrop/screen0/monitor0/color1",		{"2570u", "49884u", "45891u", "65535u"}},
	},
]]

	--[[
	/plugins/plugin-5                         clock
	/plugins/plugin-5/digital-format          %a %d %b %Y   %H:%M:%S
	/plugins/plugin-5/show-frame              false
]]

--[[
	on WHEEZY thunar icon view settings are in
		~/.config/Thunar/thunarrc
			DefaultView=ThunarDetailsView

	on JESSIE thunar icon view settings are in
		~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
]]

