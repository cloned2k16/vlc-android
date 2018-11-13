#!/bin/sh

[ $_ != $0 ] || { echo "Please source.Me !!  (. $0 ;)"; exit 666; } 

myself=$$
#-----------------------------------------------------------------------------------------------------------------------
#   please make sure you set up this before you start
#
#
                ANDROID_SDK=/home/paolo/android-sdk
                ANDROID_NDK=/home/paolo/android-sdk/android-ndk-r14b

				ANDRO_PATHS="$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools"
				
	[[ "$PATH" =~ "$ANDRO_PATHS" ]] && _inf "Already have Android PATH" || { echo -e "adding to PATH: $ANDRO_PATHS"; PATH="$PATH:$ANDRO_PATHS"; }
	
               ANDROID_HOME="$ANDROID_SDK"
           ANDROID_NDK_HOME="$ANDROID_NDK"
                
				SCRIPT_PATH=$(pwd)
				
#               ANDROID_ABI=arm   
#                   RELEASE=0
                    
# we expect to use a specific .git version of VLC ... 
# override it if it make sense to you ...
#
                    VLC_URL="https://github.com/cloned2k16/vlc.git"
               VLC_CHECKOUT=
                   VLC_HASH="a585a54f70b93a847c6f896fe75ddf63e6d7452c"
             FORCE_CHECKOUT=0
HAVE_OWN_PROTOBUF_EXTENSION=1

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
			cd "$SCRIPT_PATH"
            kill -s 2 $myself
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

main(){    
#-----------------------------------------------------------------------------------------------------------------------
phase1
#cat >/dev/null <<phase3

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
            *)              _abortError "unexpected Architecture $ARCH !!"      
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
    if [ ! -z "$HAVE_OWN_PROTOBUF_EXTENSION" ]; then     
		_wrn "skipping protobuf version check"
	else 
		[ 2 -ge $PROTOBUF_VER_HI ] && { _abortError "protobuf version < 3.x.x" : [$PROTOBUF_VER];  }
	fi	
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
		
		# TO.DO ..
		# this is not really a reliable way to do it , 
		# we better change it ..

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
	# TODO ..
	# scripts here aren't quite resilient so better split tasks 
	# even better would be to fix with a minimal error checking ...
	# workaround is to loop retry until done or give up
	DOWNLOAD_OK=$(make fetch-all | tee /dev/tty | tail -n -1)
	[ ! "$DOWNLOAD_OK" == "ake: Nothing to be done for 'fetch-all'." ]    && _inf "$DOWNLOAD_OK"  || _abortError "Error: can't download required src tools ..\n $DOWNLOAD_OK" 
	
	
	# explicit call make all 
	SHORT_RESULT=$(make all |  tee /dev/tty | tail -n -1)
	[ "$SHORT_RESULT" == "You are ready to build VLC and its contribs" ]  && _inf "$SHORT_RESULT" || _abortError "Error: can't build Extra tools ... $SHORT_RESULT"
    touch .built
	#ensure we reach first our compiled version of the tools we need ...
	EXTRA_TOOLS_BIN_PATH="$SCRIPT_PATH/vlc/extras/tools/build/bin"
	[[ "$PATH" =~ "$EXTRA_TOOLS_BIN_PATH" ]] && _inf "Already have extra tools path .." ||  PATH="$EXTRA_TOOLS_BIN_PATH:$PATH"
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

#-----------------------------------------------------------------------------------------------------------------------

    _inf "Next Steps ..."
	_log "	./makeContrib fetch-all"
	_log "	./makeContrib"
}

	parseArgs		()												{
		for i in "$@"
		do
			case $i in
				--skip-protobuf-check)
					HAVE_OWN_PROTOBUF_EXTENSION=1
				;;
				*)
					_wrn "unknown option $1"
				;;
			esac
		done
	}

parseArgs	"$@"

main 