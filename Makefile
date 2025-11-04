o=.o
exe=
rm=rm

uname := $(shell uname)
arch := $(shell uname -m)

ifeq ($(arch),x86_64)
	arch=amd64
endif

sha256sumA=sha256sum copyparty_sync_linux_$(arch).tar.gz > partycopy_linux_$(arch).tar_sha256.txt
sha256sumB=sha256sum copyparty_sync-setup.ps1 > copyparty_sync-setup_sha256.txt
sha256sumC=sha256sum setup-copyparty_sync.sh > setup-copyparty_sync_sha256.txt

# https://github.com/stpettersens/uname-windows
# https://github.com/stpettersens/sha256_chksum
ifeq ($(uname),Windows)
	o=.obj
	exe=.exe
	rm=del
	sha256sumA=sha256_chksum copyparty_sync_win64.zip
	sha256sumB=sha256_chksum copyparty_sync-setup.ps1
	sha256sumC=sha256_chksum setup-copyparty_sync.sh
endif

ifeq ($(uname),CYGWIN_NT-10.0-19044)
	o=.obj
	exe=.exe
endif

make:
	ldc2 copyparty_sync.d
	$(rm) copyparty_sync$(o)

compress:
	upx -9 copyparty_sync$(exe)

win_package:
	7z -tzip u copyparty_sync_win64.zip copyparty_sync$(exe) LICENSE
	$(sha256sumA)

linux_package:
	tar -czf partycopy_linux_$(arch).tar.gz copyparty_sync LICENSE
	$(sha256sumA)

clean:
	$(rm) copyparty_sync$(exe)

upload:
	$(sha256sumB)
	$(sha256sumC)
	@copyparty_sync
