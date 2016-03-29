# Lantern - Synology NAS support

## What's this for?
To share a Lantern on LAN all the time, it's a good choice to make it running on a NAS, since your NAS keeps running day and day.
A lot of NASs in the world, they might have different heart: __CPU__, so you should using the appropriate toolchains to build it.
Currently, I have a Synology DS212j NAS for my test, it's Marvel Kirkwood mv6281 ARM model (armv5tel). Since it's linux ARM too, it's simple, just based on linux-arm target in Makefile.

## Building Lantern

### Prerequisites

* [Linux host] If your toolchains not working on MacOSX, so your choice might be Linux.
* [Synology Tool chains](https://sourceforge.net/p/dsgpl/activity?source=project_activity) Download your cross-compling toolchains according to your CPU.
* [Node.js] To generate src/github.com/getlantern/flashlight/ui/resources.go as a dependency.

### Install toolchains

When run __Make__, in the Makefile synology.mk it trying to download toolchains specified by $(SYNO_TOOLCHAINS_URL) and install it to $(SYNO_TOOLCHAINS_PREFIX). If you install it manually, just change it in synology.mk file.

### Building

``` sh
VERSION=2.1.2-syno-dev make -f synology.mk
```

## Running Lantern on your NAS
After building it successfully, scp the lantern binary to your NAS, and make sure it's executable, then run it in background.

``` sh
chmod a+x lantern_linux_arm-syno
./lantern_linux_arm-syno -addr 0.0.0.0:8787 >/dev/null 2>&1  &
```
