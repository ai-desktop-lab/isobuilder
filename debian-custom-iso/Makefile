AI_DESKTOP_DEB_DIR ?= $(CURDIR)/../debs
DEBIAN_SUITE ?= trixie

deepin:
	sudo bash build.sh deepin
debian8:
	sudo bash build.sh debian8
debian9:
	sudo bash build.sh debian9
clean:
	sudo git clean -df

ai-desktop:
	sudo env AI_DESKTOP_DEB_DIR="$(AI_DESKTOP_DEB_DIR)" DEBIAN_SUITE="$(DEBIAN_SUITE)" \
		bash ../debian-ai-desktop-iso/build.sh
