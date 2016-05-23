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
		nmatch = 'APT::Install-Recommends',
		args = 
		{	'APT::Install-Recommends "false";',
			'APT::Install-Suggests "false";',
		},
	},
},


{ title = "kernel: disable IPv6",
	{	op = "addlines",
		path = "/etc/sysctl.conf",
		nmatch = 'net.ipv6.conf.default.disable_ipv6',
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
		nmatch = "HISTFILE=/dev/null",
		args = {"HISTFILE=/dev/null"},
	},
},

{ title = "user .profile BASE",
	{	op = "addlines",
		path = "$LSK/.profile",
		nmatch = "MANPAGER",
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
		nmatch = "export LXDEV",
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
		nmatch = 'Section "Screen"',
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

