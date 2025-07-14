SRC = db-sync.service db-sync.timer

CONFIG_DIR = $${HOME}/.config/db-sync
INSTALL_DIR = $${HOME}/.local/share/db-sync
SYSTEMD_DIR = $${HOME}/.config/systemd/user

USERNAME = $(shell whoami)

.PHONY = clean uninstall setup

clean:
	rm *.service *.timer

install: ${SRC}
	mkdir -p ${CONFIG_DIR}
	mkdir -p ${INSTALL_DIR}
	mkdir -p ${SYSTEMD_DIR}
	chmod 700 ${CONFIG_DIR}
	chmod 700 ${INSTALL_DIR}
	cp config.example ${CONFIG_DIR}/config
	cp db-sync.sh ${INSTALL_DIR}
	chmod 700 ${INSTALL_DIR}/db-sync.sh
	cp ${SRC} ${SYSTEMD_DIR}

uninstall:
	rm -r ${CONFIG_DIR}
	rm -r ${INSTALL_DIR}
	rm ${SYSTEMD_DIR}/db-sync.*

start:
	systemctl --user start db-sync.service
	systemctl --user start db-sync.timer
