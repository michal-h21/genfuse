SCRIPTSDIR=~/.local/share/nautilus/scripts
install:
	mkdir -p $(SCRIPTSDIR)
	ln -s  `readlink -f genfuse.lua` `readlink -f $(SCRIPTSDIR)`
