PREFIX ?= /usr/local

install:
	install -m 755 scanusbconnections $(PREFIX)/bin/scanusbconnections

uninstall:
	rm -f $(PREFIX)/bin/scanusbconnections
