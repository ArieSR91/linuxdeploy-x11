# linuxdeploy-x11
Linux Deploy is an APK to install Linux on Android

## Installation
Get apk from release below

Guide:
- Setting your container first click button in right-bottom corner
- In Distribution menu select Docker if the normal installation is fail
- setting your distro, but don't check Pulseaudio and GUI first
- Login as root first to fix sudo, Fill Username: root , Password: toor
- Click 3 dot button in top-right corner and install
- Then [login via SSH](#login-via-ssh): ssh root@localhost -p 22 or install [linuxdeploy launcher in termux](#launcher-in-termux): linuxdeploy -s
- Install sudo and nano to fix missing sudo in Docker image

## Login via SSH
```
ssh root@localhost -p 22
```


## Launcher in Termux
You can run linuxdeploy in termux too

Make sure you've install pulseaudio first to fix the audio
```
apt install pulseaudio root-repo tsu -y
```
Then:
```
wget https://raw.githubusercontent.com/ArieSR91/linuxdeploy-x11/main/linuxdeploy -O $PREFIX/bin/linuxdeploy; chmod 775 $PREFIX/bin/linuxdeploy; linuxdeploy
```

## Fix keyring error
Edit this 3 file in \
/etc/pam.d/login \
/etc/pam.d/su-l \
/etc/pam.d/runuser-l

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

