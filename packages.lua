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
	{ ["Xfce core"] = {true, "xserver-xorg", "xfce4-session", "xfce4-panel", "xfce4-terminal", "xfdesktop4", "xfwm4", "thunar", "catfish"}},
	{ auth = {true, "gvfs", "gksu", "xdg-utils", "gvfs-bin", "libpam-ck-connector", "policykit-1", "gvfs-daemons", "thunar-volman", "slim"}},
	{ ["UI libs"] = {true, "librsvg2-common", "gtk2-engines-xfce", "gtk2-engines-pixbuf", "libgtk2.0-bin", "libxfce4util-bin"}},
	{ compression = {true, "binutils", "sysv-rc-conf", "thunar-archive-plugin", "xarchiver", "bzip2", "zip", "unzip", "p7zip-full", "unar", "lz4"}},
	{ ["search"] = {true, "catfish", false, "python3", "python3-distutils-extra", "gir1.2-gdkpixbuf-2.0", "gir1.2-glib-2.0", "gir1.2-gtk-3.0", "gir1.2-pango-1.0", "python3-gi-cairo", "gir1.2-xfconf-0", "xfconf", "python3-pexpect", "locate"}}
}

common_packages =
{	{ icons = {true, "tango-icon-theme", "hicolor-icon-theme", "xfwm4-themes"}},
	{ fonts = {true, "ttf-dejavu", "fonts-freefont-ttf", "ttf-liberation", "ttf-mscorefonts-installer"}},				-- 2nd font is for videolan?
	{ ["crap fonts"] = {false, "gsfonts"}},
	{ ["X11 fonts"] = {false, "xfonts-100dpi", "xfonts-75dpi", "xfonts-utils", "xfonts-encodings"}},
	{ ["Xfce plugins"] = {true, "xfce4-places-plugin", "xfce4-quicklauncher-plugin", "xfce4-cpugraph-plugin", "xfce4-netload-plugin", "xfce4-taskmanager", "xfce4-notes-plugin", "xfce4-diskperf-plugin", "xfce4-mount-plugin", "xfce4-notifyd", "libnotify-bin", "xfce4-cpugraph-plugin", "xfce4-notes", "xfce4-netload-plugin", false, "xfce4-xkb-plugin", "xfce4-cpufreq-plugin", "xfce4-mixer", "xfce4-power-manager"}},
	{ admin = {true, "sysv-rc-conf", "strace", "libpaper1", "most", "ufw", false, "galternatives", "debfoster", "deborphan", "apt-file", "debtree", "ntp"}},
	{ utils = {true, "geany", "geany-plugin-lua", "geany-plugin-markdown", "galculator", "mirage", "x11-xserver-utils", "xdiskusage", "ncdu", "mc", "usbutils", "xfce4-screenshooter", "lshw-gtk", "rsync", false, "imagemagick", "qalculate-gtk"}},
	{ audio = {true, "alsa-utils", "alsa-base", "xfce4-pulseaudio-plugin", "audacity"}},
	{ laptop = {false, "firmware-linux-free", "cpufrequtils", "i8kutils", "i2c-tools", "laptop-mode-tools", "hddtemp", "lm-sensors", "xfce4-sensors-plugin", 
	  "xfce4-battery-plugin" }},
	{ wifi = {false, "wicd-gtk", "rfkill", "wicd", false, "firmware-linux-nonfree", "firmware-iwlwifi", "firmware-brcm80211", "firmware-realtek"}},	-- firmware for xps13 wifi (non-free)
	{ wifi_debug = {false, "wicd-curses", "wpagui", "wireless-tools", "wpasupplicant", "iw"}},
}

office_packages =
{	{ claws = {"claws-mail-i18n", "claws-mail-attach-remover", "claws-mail-multi-notifier", "claws-mail-fancy-plugin"}},
	{ aspell = {"aspell", "aspell-en", "aspell-fr", "aspell-es", "aspell-de", "aspell-pt-br"}},
	{ office = {"abook", "abiword", "gnumeric", "zim", false, "libreoffice", "hunspell-en-us"}},
	{ graphics = {"gimp", "inkscape", "dia"}},
	{ PDF = {"mupdf", "mupdf-tools", "evince", false, "xpdf", "autocutsel", "pdfgrep", "pdfshuffler"}},		-- should add new Jessie pdf desktop app (with printing)
	{ CHM = {"xchm"}},
	{ spellcheck = {"hunspell-en-us", "hunspell-fr-comprehensive", "hunspell-es"}},
	{ ["remote desktop"] = {"remmina-plugin-rdp", false, "x11vnc"}},					-- ! deps avahi?
}

programming_packages =
{	{ ["headers"] = {"linux-headers-$(uname -r)", "build-essential", "gdb", "cmake"}},
	{ ["utils"] = {"git", "git-gui", "gitk", "subversion", "graphviz", "graphviz-doc", "bash-doc", "xterm", "console-setup"}},	-- xterm for codelite
	{ ["dev libraries"] = {"libgtk2.0-dev", "libjpeg-dev", "libnotify-dev", "cscope", "exuberant-ctags", "libcrypto++-dev"}},
	{ ["builders"] = {"autoconf", "automake", "libtool", "autogen"}},
	{ ["multilib"] = {false, "gcc-multilib", "g++-multilib", "libc++-dev:i386", "libc++1:i386", "libgcc1:i386", "libstdc++6:i386", "libc++-helpers:i386"}},
	{ ["net libraries"] = {"libcurl4-gnutls-dev", "libpcap0.8-dev"}},
	{ ["lua"] = {"libreadline-dev", "lua-socket", "lua-posix", "libid3-tools", false, "luarocks", "lua5.3", "liblua5.3-dev"}},
	{ ["man and doc"] = {"cppman", false, "manpages-dev"}},
	{ ["sqlite"] = {"sqlite3", "libsqlite3-dev", false, "sqlite3-doc", "sqlitebrowser"}},
	{ ["Valgrind"] = {"valgrind", false, "kcachegrind", "graphviz"}},
	{ ["audio"] = {"libasound2-dev", "libsndfile1-dev", "atomicparsley"}},
	{ ["OpenGL dev libs"] = {"libgl1-mesa-dri", "libgl1-mesa-glx", "libgl1-mesa-dev", "freeglut3-dev", "libglfw3-dev", "mesa-utils", "libglu1-mesa-dev", "libglew-dev"}},	-- for wxGL dev
	-- { ["clang3.8"] = {"clang-3.8", "clang++-3.8", "libc++1", "libc++-dev", "libclang-3.8-dev", "liblldb-3.8-dev", false, "clang-format-3.8"}},		libclang-3.8-dev for codelite build
	{ ["clang3.9"] = {"clang-3.9", "libc++1", "libc++-dev", "libclang-3.9-dev", "liblldb-3.9-dev", "clang-format", "clang-tools"}},
	{ ["gcc4.9"] = {"libstdc++-4.9-dev"}},
	{ ["Vulkan"] = {"libvulkan-dev", "vulkan-utils"}},
	{ ["gcc56"] = {"g++-5", "g++-6"}},
	{ ["inhance"] = {false, "imagemagick", "gdal-bin"}},
	{ ["web"] = {false, "jq", "s3cmd"}},
	{ ["python"] = {false, "django-testproject", "python-django", "python-django-common", "python-tz", "libjs-jquery", "python-sqlparse"}},
	{ ["node.js"] = {false, "nodejs", "npm"}}
}

qemu_packages =
{	{ qemu = {true, "qemu-kvm", "qemu", "zerofree"}},
}

mount_packages =
{	{ gparted = {true, "sshfs", "bindfs", "gparted", "hdparm", "ntfs-3g", "cryptsetup", "dosfstools", "exfat-utils", "exfat-fuse", "gdisk", "meld", "dcfldd", false, "gsmartcontrol", "cryptsetup-bin", "cryptmount", "jfsutils", "kpartx", "gpart", "parted", "attr", "mtools", "blktool", "btrfs-tools", "duperemove", "btrfs-heatmap", "fdupes"}},
	{ ["CD burning"] = {true, "xfburn", false, "cdparanoia"}},
	{ iPhone = {"libimobiledevice-utils", "gvfs-backends", "gvfs-bin", "gvfs-fuse", "usbmuxd", "libusbmuxd-tools", false, "libplist-utils", "gtkpod"}},
	{ docker = {true, "docker.io", "docker-compose", false, "cockpit-docker", "python3-docker"}},
}

printing_packages =
{	{ ["CUPS printing"] = {"cups", "ghostscript", "system-config-printer", false, "hplip", "a2ps", "sam2p", "libjpeg-progs"}},
	{ ["SANE scanner"] = {"xsane", "sane"}},
}

multimedia_packages =
{
	{ web = {"iceweasel"}},
	{ video = {"vlc", "gtk-recordmydesktop", "youtube-dl", "cheese", "ristretto", download = "http://download.videolan.org/pub/libdvdcss/1.2.10/deb/libdvdcss2_1.2.9-1_i386.deb", "avidemux"}},		-- source in 1.2.13
	{ transcoding = {"oggconvert", "transmageddon", "libav-tools", "vpx-tools", "libavcodec-extra-53"}},
	{ BitTorrent = {"qbittorrent"}},
	{ dvd = {"dvdbackup", "gopchop"}},
	{ dj = {false, "mixxx", "gstreamer1.0-plugins-bad"}},
	{ bluetooth = {false, "blueman", false, "pulseaudio", "pulseaudio-module-bluetooth", "pavucontrol"}},		-- also bluez-firmware in non-free
	{ ["lxmus runtime"] = {false, "freeglut3", "libcrypto++6", "libc++1", false, "libgl1-mesa-dri"}},		-- "libglew1.13" missing
}

tools_packages =
{	{ core = {true, "wget", "lftp", "mtr", "ethtool", "dmidecode", "gdmap", "apt-file", "usbview", "htop", false, "dcfldd", "hwloc"}},
	{ online = {"curl", "socat", "geoip-bin", "nmap", "tftp", "tcpwatch-httpproxy", false, "geoip-bin", "winbind"}},
	{ serial = {"minicom", "lrzsz"}},
	{ sensor = {true, "lm-sensors", "psensor", "xfce4-sensors-plugin"}},
	{ servers = {"openssh-server", "x11vnc", false, "x2x"}},
	{ sshclient = {"keypass", "ssh-agent", "ssh-add", "ssh-askpass"}},
	{ dedup = {"rdfind"}},		-- dedup, binutils provides 'strings'
}
