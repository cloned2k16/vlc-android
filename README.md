# VLC for Android
This is an <b>un-official</b> Android port of VLC.

## License

VLC for Android is licensed under GPLv3  
(same)

## Build

originally this fork was intended to just fix some issue in compiling the original librarry,  
since there are several, we'll better try to make this as an independent un-official version instead ..

at the moment you can count on a script which try to check and setup 
a likely working environment to build the core VLC library which make sense to the android wrapper ..

so pre compilation of the native core library will work as follow ..

###### ( make sure you set the correct location to your Android S & N DK (on top of '_env.sh' file )... )


```shell
git clone https://github.com/cloned2k16/vlc-android-lib.git
cd vlc-android-lib

. ./_env.sh
./makeContrib fetch-all
./makeContrib
```
which will hopefully would get you ready to cross-compile for Android  
with:

```shell

./compile-libvlc.sh -a arm64
./compile-libvlc.sh -a arm
./compile-libvlc.sh -a x86
./compile-libvlc.sh -a mips ## ( not working in my env )

```

from here you can try to compile the Android wrapper as usual ..   
which usually compiles even in absence of the core libraries ;D   
however this is something already in our TODO list ...   


