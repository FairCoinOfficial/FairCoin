
Debian
====================
This directory contains files used to package faircoind/faircoin-qt
for Debian-based Linux systems. If you compile faircoind/faircoin-qt yourself, there are some useful files here.

## faircoin: URI support ##


faircoin-qt.desktop  (Gnome / Open Desktop)
To install:

	sudo desktop-file-install faircoin-qt.desktop
	sudo update-desktop-database

If you build yourself, you will either need to modify the paths in
the .desktop file or copy or symlink your faircoinqt binary to `/usr/bin`
and the `../../share/pixmaps/faircoin128.png` to `/usr/share/pixmaps`

faircoin-qt.protocol (KDE)

