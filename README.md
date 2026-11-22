# linuxdeploy-x11
Linux Deploy is an APK to install Linux on Android (root required)

## Installation
Get apk from release below

Guide:
- Click button in right-bottom corner, and setting your container
- In distribution menu select Docker if the normal installation is fail
- Setting your distro, but don't check Pulseaudio and GUI first
- Login as root to fix sudo, Fill Username: root , Password: toor
- Click 3 dot button in top-right corner and install
- Then [login via SSH](#login-via-ssh): ssh root@localhost -p 22 or install [linuxdeploy launcher in termux](#launcher-in-termux): linuxdeploy -s
- Install nano and sudo to fix missing sudo in Docker image
- After sudo installed in container you can login as user and check Pulseaudio and GUI now
- Then Re-configure the container to fix all

## Login via SSH
```
ssh root@localhost -p 22
```

## Launcher in Termux
You can run linuxdeploy in termux too

Make sure you've install pulseaudio in termux to fix the audio
```
apt install pulseaudio root-repo tsu -y
```
Then:
```
wget https://raw.githubusercontent.com/ArieSR91/linuxdeploy-x11/main/linuxdeploy -O $PREFIX/bin/linuxdeploy; chmod 775 $PREFIX/bin/linuxdeploy; linuxdeploy
```
Usage: linuxdeploy [options]

## Fix keyring error
Edit this 4 file in: \
/etc/pam.d/login \
/etc/pam.d/su-l \
/etc/pam.d/runuser-l \
/etc/pam.d/sshd

Comment this string: \
\#session       optional   pam_keyinit.so force revoke

# Mount point
${ANDROID_DATA} - /data \
${ANDROID_ROOT} - /system \
${EXTERNAL_STORAGE} - /sdcard

# Fix sdcard mount
If you experience a bad address when accessing the sdcard in android 9+ \
use this in the mount menu \
Source: /data/media/0 \
Target: /sdcard

