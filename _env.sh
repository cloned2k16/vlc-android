#!/bin/sh

# designed for being sourced ...

[ $_ != $0 ] || { echo "Please surceMe !!  (. $0 ;)"; exit 666; } 

#-----------------------------------------------------------------------------------------------------------------------
#   please make sure you set up this before you start
#
#
                ANDROID_SDK=/home/paolo/android-sdk
                ANDROID_NDK=/home/paolo/android-sdk/android-ndk-r18b


                       PATH="$PATH:$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools"
               ANDROID_HOME="$ANDROID_SDK"
           ANDROID_NDK_HOME="$ANDROID_NDK"
                
                ANDROID_ABI=arm   
                    RELEASE=0
                    
# we expect to use a specific .git version of VLC ... 
# override it if it make sense to you ...
#
                    VLC_URL="https://git.videolan.org/git/vlc/vlc-3.0.git"
               VLC_CHECKOUT="tags/3.0.3-1"
                   VLC_HASH=c2bb759264
             FORCE_CHECKOUT=0


# compiles native x86_64 but none of ARM !!
#VLC_HASH="5a7ad1b636"
#-----------------------------------------------------------------------------------------------------------------------
    _ansiMsg        ()                                              {   
        local col;
        local who=${FUNCNAME[ 1 ]}
        case $who in
            _log)           col="\033[0;32m"                        ;;
            _inf)           col="\033[0;36m"                        ;;
            _wrn)           col="\033[0;33m"                        ;;
            _err)           col="\033[0;31m"                        ;;
            _abortError)    col="\033[38;2;255;11;33m"              ;;
            *)              col="\033[0m"                           ;;
        esac
        echo -e "$col $@ \033[0m"
    }
#-----------------------------------------------------------------------------------------------------------------------
    _log            ()                                              { _ansiMsg "~ $@" ; }
#-----------------------------------------------------------------------------------------------------------------------
    _inf            ()                                              { _ansiMsg "~ $@" ; }
#-----------------------------------------------------------------------------------------------------------------------
    _wrn            ()                                              { _ansiMsg "! $@" ; }
#-----------------------------------------------------------------------------------------------------------------------
    _err            ()                                              { _ansiMsg "! $@" ; }
#-----------------------------------------------------------------------------------------------------------------------
    _abortError     ()                                              {
            _ansiMsg "!! $@"
            return 1
    }
    _abortIfError   ()                                              {
        if [ ! $? -eq 0 ];then
            _abortError "$@"
        fi
    }
#-----------------------------------------------------------------------------------------------------------------------

    phase1(){ _inf PHASE 1; }
    phase2(){ _inf PHASE 2; }
    phase3(){ _inf PHASE 3; }
    phase4(){ _inf PHASE 4; }
    
#-----------------------------------------------------------------------------------------------------------------------
phase1
#cat >/dev/null <<phase4

#-----------------------------------------------------------------------------------------------------------------------
    ARCH="$(uname -p)"
    case  $ARCH  in
            i386|i686)      _log "we got a 32 bit OS"
           
                        ;;
            x86_64)         _log "64 bit  OS adding support for 32 bit"
                            _log "adding i386 architecture .."
                            sudo dpkg --add-architecture i386
                            _log "update repositories .."
                            sudo apt-get update
                            _log "installl support libraries .."
                            sudo apt-get install zlib1g:i386 libstdc++6:i386 libc6:i386
                        ;;
            *)              _err    "unexpected Architecture $ARCH !!"      
                        ;;
    esac
#-----------------------------------------------------------------------------------------------------------------------
    
    _log "getting required packages ..."
    sudo apt-get install                \
                    automake            \
                    yasm                \
                    gperf               \
                    libasound2-dev      \
                    liblivemedia-dev    \
                    ant                 \
                    autopoint           \
                    cmake               \
                    build-essential     \
                    libtool             \
                    patch               \
                    pkg-config          \
                    ragel               \
                    subversion          \
                    unzip git           \
                    openjdk-8-jre       \
                    openjdk-8-jdk       \
                    protobuf-compiler
                    
#-----------------------------------------------------------------------------------------------------------------------
phase2

#-----------------------------------------------------------------------------------------------------------------------
    PROTOBUF_VER="$(sudo apt-get -s install protobuf-compiler | grep version)"
    PROTOBUF_VER="${PROTOBUF_VER##* (}"
    PROTOBUF_VER=${PROTOBUF_VER%%)*}
    PROTOBUF_VER_HI=${PROTOBUF_VER%%.*}
    _inf protobuf version is: $PROTOBUF_VER
#-----------------------------------------------------------------------------------------------------------------------
    [ 2 -ge $PROTOBUF_VER_HI ] && { _err "protobuf version < 3.x.x" : [$PROTOBUF_VER]; exit; }
#-----------------------------------------------------------------------------------------------------------------------
    DONE=0
    ATTEMPTS=3
    BASE_DIR="$(pwd)"
    while [ $DONE -eq 0 ]
    do  
        if [ ! -d "vlc" ]; then
            _log "VLC source not found, cloning it .."
            git clone $VLC_URL vlc
            _abortIfError "can't clone VLC .."
            cd vlc
            [ -z "$VLC_CHECKOUT" ] || { git checkout "$VLC_CHECKOUT";   _abortIfError "can't checkout $VLC_CHECKOUT ..";    }
        else
            _log "VLC source found"
            cd vlc
        fi
        _inf "check integrity .."
        if ! git fsck --full;then 
            ATTEMPTS=$((ATTEMPTS-1))
            _wrn "Integrity check failed! ($ATTEMPTS attempts left)"
            cd ..
            rm -Rf vlc
            if [ -z $ATTEMPTS ] ; then
                _abortError "can't get the VLC sources .."
            fi
        else
            _inf "check commit HASH"
            if  ! $(git cat-file -e ${VLC_HASH} 2>/dev/null); then
                _err "can't find expected HASH"
                # we can eventually make this optional
                _wrn "we don't reconize this version,\n   compile it at your own risk ..."
                
                if [ "$FORCE_CHECKOUT" = 1 ]; then
                    git reset --hard ${TESTED_HASH}
                    
                fi
            else
                _log "Ok+ this is a tested commit .." 
            fi
            DONE=1
        fi 
    done            
    cd "$BASE_DIR"
#-----------------------------------------------------------------------------------------------------------------------
phase3
    
#-----------------------------------------------------------------------------------------------------------------------
    NATIVE_BUILD_DIR="native-build"
    BASE_DIR="$(pwd)"
    
    cd vlc

    _inf "bootstrapping extra tools .."
    cd extras/tools/
    ./bootstrap
    touch .botstrapped
    _inf "building extra tools .."
    make
    touch .built
    cd ../../

    _inf "bootstrapping main package .."
    [ -d "$NATIVE_BUILD_DIR" ] || mkdir "$NATIVE_BUILD_DIR"
    cd "$NATIVE_BUILD_DIR"
    ../bootstrap
    touch .botstrapped
    cd ../
    
    
    _inf "bootstrapping contrib libraries .."
    cd contrib
    [ -d "$NATIVE_BUILD_DIR" ] || mkdir "$NATIVE_BUILD_DIR"
    cd "$NATIVE_BUILD_DIR"
    ../bootstrap
    touch .botstrapped
    # make  
    _wrn "use makeContrib <...>\n    instead\n       or change dir to $(pwd)"
    
    cd "$BASE_DIR"
#-----------------------------------------------------------------------------------------------------------------------
phase4

#_abortError "The End."
#-----------------------------------------------------------------------------------------------------------------------
    