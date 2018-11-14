#!/bin/sh

[ $_ != $0  ] || { echo "Please source.Me !!  ( . $0 )"; exit 666; } 

. ./utils.sh

MYSELF=$$
SCRIPT_PATH=$(pwd)

#-----------------------------------------------------------------------------------------------------------------------
#   please make sure you set up this before you start
#
#
                ANDROID_SDK=/home/paolo/android-sdk
                ANDROID_NDK=/home/paolo/android-sdk/android-ndk-r14b

#
#				
				ANDRO_PATHS="$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools"
				
				[[ "$PATH" =~ "$ANDRO_PATHS" ]] && _inf "Already have Android PATH" || { _wrn "adding to PATH: $ANDRO_PATHS"; PATH="$PATH:$ANDRO_PATHS"; }
	
               ANDROID_HOME="$ANDROID_SDK"
           ANDROID_NDK_HOME="$ANDROID_NDK"
                
# not used (yet)				
#               ANDROID_ABI=arm   
#                   RELEASE=0
                    
# we expect to use a specific .git version of VLC ... 
# override it if it make sense to you ...
#
                    VLC_URL="https://github.com/cloned2k16/vlc-3.0.git"
               VLC_CHECKOUT=
                   VLC_HASH="74d3d1d5e9a96fc2ba4c9410214a65008643d05e"
             FORCE_CHECKOUT=0
HAVE_OWN_PROTOBUF_EXTENSION=1

_inf "here we go"
#-----------------------------------------------------------------------------------------------------------------------

    phase1(){ _inf PHASE 1; }
    phase2(){ _inf PHASE 2; }
    phase3(){ _inf PHASE 3; }
    phase4(){ _inf PHASE 4; }
#-----------------------------------------------------------------------------------------------------------------------
main(){    
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
    
	#ensure we reach first our compiled version of the tools we need ...
	EXTRA_TOOLS_BIN_PATH="$SCRIPT_PATH/vlc/extras/tools/build/bin"
	[[ "$PATH" =~ "$EXTRA_TOOLS_BIN_PATH" ]] && _inf "Already have extra tools path .." ||  PATH="$EXTRA_TOOLS_BIN_PATH:$PATH"

    _inf "bootstrapping extra tools .."
    cd vlc/extras/tools/
    ./bootstrap 2>&1 | tee /dev/tty > bootstrap.log 
	BOOT_EXTRA_TOOLS=$(tail -n -1 bootstrap.log)
    case $BOOT_EXTRA_TOOLS in
		*"To-be-built packages:"*) 		        touch .botstrapped 									;;
		*"bootstrap: Nothing to be done"*)		_inf "Tools are already build or correct" 			;;
		*) 										_abortError "unexpected result: $BOOT_EXTRA_TOOLS" 	;;
    esac  											
	
    _inf "building extra tools .."
	# TODO ..
	# scripts here aren't quite resilient so better split tasks 
	# even better would be to fix with a minimal error checking ...
	# workaround is to loop retry until done or give up
	#DOWNLOAD_OK=$(make fetch-all | tee /dev/tty | tail -n -1)
	make fetch-all 2>&1 | tee /dev/tty > make_fetch-all.log
	DOWNLOAD_OK=$(tail -n -1 make_fetch-all.log)
	[ ! "$DOWNLOAD_OK" == "ake: Nothing to be done for 'fetch-all'." ]     && _inf "$DOWNLOAD_OK"                   || _abortError "Error: can't download required src tools ..\n $DOWNLOAD_OK" 
	
	
	# explicit call make all 
	make all 2>&1 |  tee /dev/tty > make_all.log
	SHORT_RESULT=$(tail -n -1 make_all.log)
	[ "$SHORT_RESULT" == "You are ready to build VLC and its contribs" ]  && { _inf "$SHORT_RESULT"; touch .built; } || _abortError "Error: can't build Extra tools ... $SHORT_RESULT"
    
    cd ../../

    _inf "bootstrapping main package .."
    [ -d "$NATIVE_BUILD_DIR" ] || mkdir "$NATIVE_BUILD_DIR"
    cd "$NATIVE_BUILD_DIR"
	../bootstrap | tee /dev/tty > bootstrap.log
    BOOT_NATIVE_BUILD=$(tail -n -1 bootstrap.log)
	[ "$BOOT_NATIVE_BUILD" == "Successfully bootstrapped" ] && { _inf "$BOOT_NATIVE_BUILD"; touch .botstrapped; }    || _abortError "Error in bootstrap: $BOOT_NATIVE_BUILD"
	 
    cd ../
    
    _inf "bootstrapping contrib libraries .."
    cd contrib
    [ -d "$NATIVE_BUILD_DIR" ] || mkdir "$NATIVE_BUILD_DIR"
    cd "$NATIVE_BUILD_DIR"
    ../bootstrap | tee /dev/tty > bootstrap.log
    BOOT_CONTRIB_BUILD=$(tail -n -1 bootstrap.log)
	[[ "$BOOT_CONTRIB_BUILD" =~ "show this text" ]] && { _inf "$BOOT_CONTRIB_BUILD"; touch .botstrapped; }    || _abortError "Error in bootstrap: $BOOT_CONTRIB_BUILD"

    # make  
    _wrn "use makeContrib <...>\n    instead\n       or change dir to $(pwd)"
    
    cd "$BASE_DIR"
#-----------------------------------------------------------------------------------------------------------------------
phase4

#-----------------------------------------------------------------------------------------------------------------------

    _inf "Next Steps ..."
	_log "	./makeContrib fetch-all"
	_log "	./makeContrib"
	unset -f main
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
		unset -f parseArgs
	}

_inf "parsing args.."

parseArgs	"$@"

_inf "call to main.."
main 