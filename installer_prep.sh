#!/bin/bash
#
# This script looks at the operating system, architecture, bit type, etc., to determine
# whether or not the system is supported by NadekoBot. Once the system is deemed as
# supported, the master installer will be downloaded and executed.
#
# Comment key for '[letter].[number].':
#   A.1. - Sed for linux || Sed for macOS.
#   B.1. - Grouping One
#   B.2. - Grouping Two
#   B.3. - Grouping Three
#
########################################################################################
#### [ Exported and/or Globally Used Variables ]


# Used to keep track of changes to 'linuxAIO.sh'.
# Refer to the '[ Prepping ]' section of this script for more information.
current_linuxAIO_revision="26"
# Name of the master installer to be downloaded.
master_installer="nadeko_master_installer.sh"

## Modify output text color.
export _YELLOW=$'\033[1;33m'
export _GREEN=$'\033[0;32m'
export _CYAN=$'\033[0;36m'
export _RED=$'\033[1;31m'
export _NC=$'\033[0m'
export _GREY=$'\033[0;90m'
export _CLRLN=$'\r\033[K'

## PURPOSE: The '--no-hostname' flag for 'journalctl' only works with systemd 230 and
##          later. So if systemd is older than 230, $_NO_HOSTNAME will not be created.
{
    journalctl_version=$(journalctl --version) \
        && journalctl_version=${journalctl_version:1:1}

    if ((journalctl_version >= 230)) 2>/dev/null; then
        export _NO_HOSTNAME="--no-hostname"
    fi
} 2>/dev/null


#### End of [ Exported and/or Globally Used Variables ]
########################################################################################
#### [ Functions ]


detect_sys_info() {
    ####
    # Function Info: Identify the operating system, version number, architecture, bit
    #                type (32 or 64), etc.
    ####

    ## For Linux.
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        _DISTRO="$ID"
        _VER="$VERSION_ID"  # Version: x.x.x...
        _SVER=${_VER//.*/}  # Version: x
        pname="$PRETTY_NAME"
    ## For macOS.
    else
        _DISTRO=$(uname -s)
        if [[ $_DISTRO = "Darwin" ]]; then
            _VER=$(sw_vers -productVersion)  # macOS version: x.x.x
            _SVER=${_VER%.*}                 # macOS version: x.x
            pname="macOS"
        else
            _VER=$(uname -r)
        fi
    fi

    ## Identify bit and architecture type.
    case $(uname -m) in
        x86_64) bits="64"; _ARCH="x64" ;;
        i*86)   bits="32"; _ARCH="x86" ;;
        armv*)  bits="32"; _ARCH="?" ;;
        *)      bits="?";  _ARCH="?" ;;
    esac
}

linuxAIO_update() {
    ####
    # Function Info: Download the latest version of 'linuxAIO.sh' if $_LINUXAIO_REVISION
    #                and $current_linuxAIO_revision aren't of equal value.
    #
    # Purpose: Since 'linuxAIO.sh' remains on the user's system, any changes to the code
    #          that are pushed to github, are never applied to the version on the user's
    #          system. Whenever the values of $_LINUXAIO_REVISION and
    #          $current_linuxAIO_revision do not match, the newest version of
    #          'linuxAIO.sh' is retrieved from github.
    #
    # ! Revision Note: As another important note, only 'linuxAIO.sh' files with a
    #                  revision number of 9 or later will utilize this function.
    #                  Breaking changes occurred between revision 8 and 9, and as a
    #                  result, I've decided that the end-user will be required to
    #                  manually download the latest version from github. The script will
    #                  provide the user with the appropriate command to do this, based
    #                  on the configurations in their current 'linuxAIO.sh'.
    ####

    ## Save the values of the current Configuration Variables specified in
    ## 'linuxAIO.sh', to be set in the new 'linuxAIO.sh'.
    ## NOTE: Declaration and instantiation is separated at the recommendation by
    ##       shellcheck.
    local installer_branch                                       # B.1.
    local installer_branch_found                                 # B.1.
    installer_branch=$(grep '^installer_branch=.*' linuxAIO.sh)  # B.1.
    installer_branch_found="$?"	                                 # B.1.
    local allow_run_as_root                                        # B.2.
    local allow_run_as_root_found                                  # B.2.
    allow_run_as_root=$(grep '^allow_run_as_root=.*' linuxAIO.sh)  # B.2.
    allow_run_as_root_found="$?"                                   # B.2.
    local nadeko_install_version                                                     # B.3.
    local nadeko_install_version_found                                               # B.3.
    nadeko_install_version=$(grep '^export _NADEKO_INSTALL_VERSION=.*' linuxAIO.sh)  # B.3.
    nadeko_install_version_found="$?"                                                # B.3.

    echo "$_YELLOW'linuxAIO.sh' is not up to date$_NC"
    echo "Downloading latest 'linuxAIO.sh'..."
    curl -O "$_RAW_URL"/linuxAIO.sh \
        && sudo chmod +x linuxAIO.sh

    echo "Applying existing configurations to the new 'linuxAIO.sh'..."

    ####################################################################################
    #### [[ $installer_branch ]]


    ## Set $installer_branch inside of the new 'linuxAIO.sh'.
    if [[ $installer_branch_found = 0 ]]; then
        # A.1.
        sed -i "s/^installer_branch=.*/$installer_branch/" linuxAIO.sh \
            || sed -i '' "s/^installer_branch=.*/$installer_branch/" linuxAIO.sh
    fi


    #### End of [[ $installer_branch ]]
    ####################################################################################
    #### [[ $allow_run_as_root ]]


    ## Set $allow_run_as_root inside of the new 'linuxAIO.sh'.
    if [[ $allow_run_as_root_found = 0 ]]; then
        # A.1.
        sed -i "s/^allow_run_as_root=.*/$allow_run_as_root/" linuxAIO.sh \
            || sed -i '' "s/^allow_run_as_root=.*/$allow_run_as_root/" linuxAIO.sh
    fi


    #### End of [[ $allow_run_as_root ]]
    ####################################################################################
    #### [[ $_NADEKO_INSTALL_VERSION ]]


    ## Set $nadeko_install_version inside of the new 'linuxAIO.sh'.
    if [[ $nadeko_install_version_found = 0 ]]; then
        # A.1.
        sed -i "s/^export _NADEKO_INSTALL_VERSION=.*/$nadeko_install_version/" linuxAIO.sh \
            || sed -i '' "s/^export _NADEKO_INSTALL_VERSION=.*/$nadeko_install_version/" linuxAIO.sh
    fi


    #### End of [[ $_NADEKO_INSTALL_VERSION ]]
    ####################################################################################
    #### [[ Finishing up ]]


    echo "${_GREEN}Successfully downloaded the newest version of 'linuxAIO.sh' and" \
        "applied changes to the newest version of 'linuxAIO.sh'$_NC"
    clean_up "0" "Exiting" "true"


    #### End of [[ Finishing up ]]
    ####################################################################################
}

unsupported() {
    ####
    # Function Info: Provide the end-user with the option to continue, even if their
    #                system isn't officially supported.
    ####

    echo "${_RED}Your operating system/Linux Distribution is not OFFICIALLY supported" \
        "for the installation, setup, and/or use of NadekoBot" >&2
    echo "${_YELLOW}WARNING: By continuing, you accept that unexpected behaviors" \
        "may occur. If you run into any errors or problems with the installation and" \
        "use of the NadekoBot, you are on your own. We do not provide support for" \
        "distributions that we don't officially support.$_NC"
    read -rp "Would you like to continue anyways? [y/N] " choice
    # Convert user input to lowercase.
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    case "$choice" in
        y|yes) clear -x; execute_master_installer ;;
        n|no)  clean_up "0" "Exiting" ;;
        *)     clean_up "0" "Exiting" ;;
    esac
}

execute_master_installer() {
    ####
    # Function Info: Download and execute 'nadeko_master_installer.sh'.
    ####

    _DOWNLOAD_SCRIPT "$master_installer" "$master_installer" "true"
    ./nadeko_master_installer.sh
    clean_up "$?" "Exiting"
}

clean_up() {
    ####
    # Function Info: Cleanly exit the installer by removing files that aren't required
    #                unless the installer is currently running.
    #
    # Parameters:
    #   $1 - Exit status code.
    #   $2 - Output text.
    #   $3 - Determines if 'Cleaning up...' needs to be printed with a new-line symbol.
    ####

    # Files to be removed.
    local installer_files=("credentials_setup.sh" "installer_prep.sh"
        "prereqs_installer.sh" "nadeko_latest_installer.sh" "nadeko_runner.sh"
        "nadeko_master_installer.sh")

    ### PURPOSE: Sometimes the output requires the use of a new-line symbol to separate
    ###          the previous text, though sometimes it doesn't.
    if [[ $3 = true ]]; then echo "Cleaning up..."
    else                     echo -e "\nCleaning up..."
    fi

    cd "$_WORKING_DIR" || {
        echo "${_RED}Failed to move to project root directory$_NC" >&2
        exit 1
    }

    # Remove the version of NadekoBot that had just been downloaded to the system.
    if [[ -d NadekoTMPDir ]]; then rm -rf NadekoTMPDir
    fi

    ## Remove any and all files specified in $installer_files.
    for file in "${installer_files[@]}"; do
        if [[ -f $file ]]; then rm "$file"
        fi
    done

    echo "$2..."
    exit "$1"
}


########################################################################################
#### [[ Functions To Be Exported ]]


_DOWNLOAD_SCRIPT() {
    ####
    # Function Info: Download the specified script and modify it's execution
    #                permissions.
    #
    # Parameters:
    #   $1 - Name of script to download.
    #   $2 - Name to rename $1 with.
    ####

    if [[ ! $3 ]]; then echo "Downloading '$1'..."
    fi
    curl -s "$_RAW_URL"/"$1" -o "$2"
    sudo chmod +x "$2"
}


#### End of [[ Functions To Be Exported ]]
########################################################################################

#### End of [ Functions ]
########################################################################################
#### [ Error Traps ]


# Execute when the user uses 'Ctrl + Z', 'Ctrl + C', or otherwise forcefully exits the
# installer.
trap 'echo -e "\n\nScript forcefully stopped"
    clean_up "2" "Exiting" "true"' \
    SIGINT SIGTSTP SIGTERM


#### End of [ Error Traps ]
########################################################################################
#### [ Prepping ]


# If the current 'linuxAIO.sh' revision is number 9 or later...
if [[ $_LINUXAIO_REVISION && $_LINUXAIO_REVISION != "$current_linuxAIO_revision" ]]; then
    linuxAIO_update
# If the current 'linuxAIO.sh' revision is number 8 or earlier...
elif [[ $linuxAIO_revision && $linuxAIO_revision != "$current_linuxAIO_revision" ]]; then
    echo "$_YELLOW'linuxAIO.sh' is not up to date"
    echo "${_CYAN}Due to some breaking changes between revision 8 and 9 you are" \
        "required to manually download the newest version of 'linuxAIO.sh'. You can" \
        "do so by executing the following:"
    echo "    mv linuxAIO.sh linuxAIO.sh.old && curl -O" \
        "https://raw.githubusercontent.com/$installer_repo/$installer_branch/linuxAIO.sh" \
        "&& sudo chmod +x linuxAIO.sh$_NC"
    clean_up "0" "Exiting" "true"
fi

# Change the working directory to the location of the executed scrpt.
cd "$(dirname "$0")" || {
    echo "${_RED}Failed to change working directory" >&2
    echo "${_CYAN}Change your working directory to that of the executed script$_NC"
    clean_up "1" "Exiting" "true"
}

export _WORKING_DIR="$PWD"
export _INSTALLER_PREP="$_WORKING_DIR/installer_prep.sh"


#### End of [ Prepping ]
########################################################################################
#### [ Main ]


clear -x  # Clear the screen of any text.

detect_sys_info
export _DISTRO _SVER _VER _ARCH
export -f _DOWNLOAD_SCRIPT

# Use $_DISTRO if $pname is unset or null.
echo "SYSTEM INFO
Bit Type: $bits
Architecture: $_ARCH
Distro: ${pname:=$_DISTRO}
Distro Version: $_VER
"

### Check if the operating system is supported by NadekoBot and installer.
if [[ $bits = 64 ]]; then
    # Ubuntu:
    #   16.04
    #   18.04
    #   20.04
    if [[ $_DISTRO = "ubuntu" ]]; then
        case "$_VER" in
            16.04|18.04|20.04) execute_master_installer ;;
            *)                 unsupported ;;
        esac
    # Debian:
    #   9
    #   10
    elif [[ $_DISTRO = "debian" ]]; then
        case "$_SVER" in
            9|10) execute_master_installer ;;
            *)    unsupported ;;
        esac
    # Linux Mint:
    #   18
    #   19
    #   20
    elif [[ $_DISTRO = "linuxmint" ]]; then
        case "$_SVER" in
            18|19|20) execute_master_installer ;;
            *)        unsupported ;;
        esac
    # macOS:
    #   10.14
    #   10.15
    #   11.*
    elif [[ $_DISTRO = "Darwin" ]]; then
        case "$_SVER" in
            10.14|10.15) execute_master_installer ;;
            11|11.*)     execute_master_installer ;;
            *)           unsupported ;;
        esac
    else
        unsupported
    fi
else
    unsupported
fi


#### End of [ Main ]
########################################################################################
