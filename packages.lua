-- package definitions

--[[
if (not Debian) then
	print("launch from main()!")
	os.exit(-1)
end
]]

pkg_to_add_groups =
{

	-- add default groups -- NO LONGER EFFECTIVE ???
	["gvfs"] = {"disk", "staff", "mail", "adm"},
	["cupsd"] = "lpadmin",
	["minicom"] = "dialout",
	["qemu-kvm"] = "kvm",
}

distro_packages =
{	
	{ ["Xfce core"] = {true, "xserver-xorg", "xfce4-session", "xfce4-panel", "xfce4-terminal", "xfdesktop4", "xfwm4", "thunar"}},
	{ auth = {true, "gvfs", "gksu", "xdg-utils", "gvfs-bin", "libpam-ck-connector", "policykit-1", "gvfs-daemons", "thunar-volman", "slim"}},
	{ ["UI libs"] = {true, "librsvg2-common", "gtk2-engines-xfce", "gtk2-engines-pixbuf", "libgtk2.0-bin", "libxfce4util-bin"}},
	{ compression = {true, "binutils", "sysv-rc-conf", "thunar-archive-plugin", "xarchiver", "bzip2", "zip", "unzip", "p7zip-full"}}
}

common_packages =
{	{ icons = {true, "tango-icon-theme", "hicolor-icon-theme", "xfwm4-themes"}},
	{ fonts = {true, "ttf-dejavu", "fonts-freefont-ttf", "ttf-liberation"}},				-- 2nd font is for videolan?
	{ ["crap fonts"] = {false, "gsfonts"}},
	{ ["X11 fonts"] = {false, "xfonts-100dpi", "xfonts-75dpi", "xfonts-utils", "xfonts-encodings"}},
	{ ["Xfce plugins"] = {true, "xfce4-places-plugin", "xfce4-quicklauncher-plugin", "xfce4-cpugraph-plugin", "xfce4-netload-plugin", "xfce4-taskmanager", "xfce4-notes-plugin", "xfce4-diskperf-plugin", "xfce4-mount-plugin", "xfce4-notifyd", "libnotify-bin", false, "xfce4-xkb-plugin", "xfce4-cpufreq-plugin", "xfce4-mixer"}},
	{ admin = {true, "sysv-rc-conf", "strace", "libpaper1", "most", "ufw", false, "galternatives", "debfoster", "deborphan", "apt-file", "debtree", "ntp"}},
	{ utils = {true, "geany", "geany-plugin-lua", "galculator", "mirage", "x11-xserver-utils", "xdiskusage", "ncdu", "mc", "usbutils", "xfce4-screenshooter", "lshw-gtk", false, "rsync", "qalculate-gtk"}},
	{ audio = {true, "alsa-utils", "alsa-base"}},
	{ laptop = {false, "firmware-linux-free", "cpufrequtils", "i8kutils", "i2c-tools", "laptop-mode-tools", "hddtemp", "lm-sensors", "xfce4-sensors-plugin", 
	  "xfce4-battery-plugin" }},
	{ wifi = {false, "wicd-gtk", "rfkill", "wicd", false, "firmware-iwlwifi"}},	-- firmware for xps13 wifi (non-free)
	{ wifi_debug = {false, "wpagui", "wireless-tools", "wpasupplicant", "iw"}},
}

office_packages =
{	{ claws = {"claws-mail", "claws-mail-i18n", "claws-mail-attach-remover", "claws-mail-multi-notifier"}},
	{ aspell = {"aspell", "aspell-en", "aspell-fr", "aspell-es", "aspell-de", "aspell-pt-br"}},
	{ office = {"abook", "abiword", "gnumeric", "zim"}},
	{ graphics = {"gimp", "inkscape", "dia"}},
	{ PDF = {"mupdf", "mupdf-tools", "evince", false, "autocutsel", "pdfgrep", "pdfshuffler"}},		-- should add new Jessie pdf desktop app (with printing)
	{ CHM = {"xchm"}},
	{ ["remote desktop"] = {"remmina-plugin-vnc", false, "x11vnc"}},					-- ! deps avahi?
}

programming_packages =
{	{ ["headers"] = {"linux-headers-$(uname -r)", "build-essential", "gdb", "cmake"}},
	{ ["utils"] = {"git", "git-gui", "gitk", "subversion", "graphviz", "graphviz-doc", "bash-doc", "xterm"}},	-- xterm for codelite
	{ ["dev libraries"] = {"libgtk2.0-dev", "libjpeg-dev", "libnotify-dev", "cscope", "exuberant-ctags", "libcrypto++-dev"}},
	{ ["builders"] = {"autoconf", "automake", "libtool", "autogen"}},
	{ ["multilib"] = {"gcc-multilib", "g++-multilib", "libc++-dev:i386", "libc++-dev:i386", "libc++1:i386", "libgcc1:i386", "libstdc++6:i386", "libc++-helpers:i386"}},
	{ ["net libraries"] = {"libcurl4-gnutls-dev", "libpcap0.8-dev"}},
	{ ["lua"] = {"libreadline-dev", "lua-socket", "lua-posix", "libid3-tools", false, "luarocks", "lua5.3", "liblua5.3-dev"}},
	{ ["man and doc"] = {"cppman", false, "manpages-dev"}},
	{ ["sqlite"] = {"sqlite3", "libsqlite3-dev", false, "sqlite3-doc", "sqlitebrowser"}},
	{ ["Valgrind"] = {"valgrind"}},
	{ ["audio"] = {"libasound2-dev", "libsndfile1-dev", "atomicparsley"}},
	{ ["OpenGL dev libs"] = {"libgl1-mesa-dri", "libgl1-mesa-glx", "libgl1-mesa-dev", "freeglut3-dev", "libglfw3-dev", "mesa-utils", "libglu1-mesa-dev", "libglew-dev"}},	-- for wxGL dev
	{ ["clang3.5"] = {"clang-3.5", "libc++1", "libc++-dev", "libclang-3.5-dev", "clang-format-3.5", "liblldb-3.5-dev"}},
	{ ["gcc4.9"] = {"gcc-4.9", "libstdc++-4.9-dev"}},
	{ ["Vulkan"] = {"libvulkan-dev", "vulkan-utils"}},
	{ ["gcc 5 & 6"] = {"g++-5", "g++-6"}},
}

qemu_packages =
{	{ qemu = {true, "qemu-kvm", "qemu", "zerofree"}},
}

mount_packages =
{	{ gparted = {true, "sshfs", "bindfs", "gparted", "hdparm", "ntfs-3g", "cryptsetup", "dosfstools", "exfat-utils", false, "cryptsetup-bin", "cryptmount", "jfsutils", "kpartx", "gpart", "parted", "attr", "mtools", "btrfs-tools", "blktool"}},
	{ ["CD burning"] = {true, "xfburn", false, "cdparanoia"}},
	{ iPhone = {"libimobiledevice-utils", "gvfs-backends", "gvfs-bin", "gvfs-fuse", "usbmuxd", "libusbmuxd-tools", "libplist-utils", false, "gtkpod"}},
}

printing_packages =
{	{ ["CUPS printing"] = {"cups", "ghostscript", "system-config-printer", false, "hplip", "a2ps", "sam2p", "libjpeg-progs"}},
	{ ["SANE scanner"] = {"xsane"}},
}

multimedia_packages =
{
	{ web = {"iceweasel"}},
	{ video = {"vlc", "gtk-recordmydesktop", "youtube-dl", download = "http://download.videolan.org/pub/libdvdcss/1.2.10/deb/libdvdcss2_1.2.9-1_i386.deb"}},		-- source in 1.2.13
	{ transcoding = {"oggconvert", "transmageddon", "libav-tools", "vpx-tools", "libavcodec-extra-53"}},
	{ BitTorrent = {"qbittorrent"}},
	{ DVB = {"dvb-apps", false, "me-tv", "w-scan"}},
	{ dvd = {"dvdbackup", "gopchop"}},
	{ dj = {false, "mixxx", "gstreamer1.0-plugins-bad"}},
	{ bluetooth = {false, "blueman", false, "pulseaudio", "pulseaudio-module-bluetooth", "pavucontrol"}},		-- also bluez-firmware in non-free
}

tools_packages =
{	{ core = {true, "wget", "lftp", "mtr", "ethtool", "dmidecode", "gdmap", "apt-file"}},
	{ online = {"curl", "socat", "geoip-bin", "nmap", "tftp", "tcpwatch-httpproxy", false, "geoip-bin", "winbind"}},
	{ serial = {"minicom", "lrzsz"}},
	{ servers = {"openssh-server", "x11vnc"}},
	{ dedup = {"rdfind"}},		-- dedup, binutils provides 'strings'
}
