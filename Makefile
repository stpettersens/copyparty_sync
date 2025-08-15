o=.o
exe=
rm=rm

uname := $(shell uname)

# https://github.com/stpettersens/uname-windows
ifeq ($(uname),Windows)
	o=.obj
	exe=.exe
	rm=del
endif

make:
	ldc2 copyparty_sync.d
	$(rm) copyparty_sync$(o)

compress:
	upx -9 copyparty_sync$(exe)

clean:
	$(rm) copyparty_sync$(exe)
