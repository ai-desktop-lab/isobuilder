deepin:
	sudo bash build.sh deepin
debian8:
	sudo bash build.sh debian8
debian9:
	sudo bash build.sh debian9
clean:
	sudo git clean -df

ai-desktop:
	sudo bash ../debian-ai-desktop-iso/build.sh

debian:
	sudo env DEBIAN_SUITE=trixie LB_MODE=debian \
		bash ../debian-ai-desktop-iso/build.sh

ubuntu:
	sudo env DEBIAN_SUITE=resolute LB_MODE=ubuntu \
		DEBIAN_MIRROR=https://archive.ubuntu.com/ubuntu \
		DEBIAN_ARCHIVE_AREAS='main restricted universe multiverse' \
		bash ../debian-ai-desktop-iso/build.sh

fedora:
	sudo env OS_FAMILY=fedora OS_RELEASE=43 \
		bash ../rpm-custom-iso/build.sh

rocky:
	sudo env OS_FAMILY=rocky OS_RELEASE=9 \
		bash ../rpm-custom-iso/build.sh

rocky10:
	sudo env OS_FAMILY=rocky OS_RELEASE=10 \
		bash ../rpm-custom-iso/build.sh
