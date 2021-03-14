#!/bin/bash
#
# This script looks at the operating system, architecture, bit type, etc., to
# determine whether or not the system is supported by NadekoBot. Once the system
# is deemed as supported, the master installer will be downloaded and executed.
#
# Note: All variables not defined in this script, are exported from
# 'linuxAIO.sh'.
#
################################################################################
#### [ Exported and/or Globally Used Variables ]


current_linuxAIO_revision="8"

export yellow=$'\033[1;33m'
export green=$'\033[0;32m'
export cyan=$'\033[0;36m'
export red=$'\033[1;31m'
export nc=$'\033[0m'
export clrln=$'\r\033[K'
export grey=$'\033[0;90m'
export installer_prep_pid=$$

# The '--no-hostname' flag for journalctl only works with systemd 230 and later
if (($(journalctl --version | grep -oP "[0-9]+" | head -1) >= 230)) 2>/dev/null; then
    export no_hostname="--no-hostname"
fi


#### End of [ Exported and/or Globally Used Variables ]
################################################################################
#### [ Error Traps ]


# Makes it possible to cleanly exit the installer by cleaning up files that
# aren't required unless currently being run
clean_exit() {
    local installer_files=("credentials_setup.sh" "installer_prep.sh"
        "prereqs_installer.sh" "nadeko_latest_installer.sh"
        "nadeko_master_installer.sh")

    if [[ $3 = true ]]; then echo "Cleaning up..."; else echo -e "\nCleaning up..."; fi
    for file in "${installer_files[@]}"; do
        if [[ -f $file ]]; then rm "$file"; fi
    done

    echo "$2..."
    exit "$1"
}

trap "echo -e \"\n\nScript forcefully stopped\"
    clean_exit \"1\" \"Exiting\" \"true\"" \
    SIGINT SIGTSTP SIGTERM


#### End of [ Error Traps ]
################################################################################
#### [ Prepping ]


# Makes sure that linuxAIO.sh is up to date
if [[ $linuxAIO_revision != $current_linuxAIO_revision ]]; then
    installer_branch=$(grep 'export installer_branch=' linuxAIO.sh | awk -F '"' '{print $2}');

    echo "${yellow}'linuxAIO.sh' is not up to date${nc}"
    echo "Downloading latest 'linuxAIO.sh'..."
    curl https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/linuxAIO.sh \
            -o linuxAIO.sh || {
        echo "${red}Failed to download latest 'linuxAIO.sh'...${nc}" >&2
        clean_exit "1" "Exiting" "true"
    }
    echo "Modifying 'installer_branch'..."
    sed -i "s/export installer_branch=.*/export installer_branch=\"$installer_branch\"/" linuxAIO.sh
    sudo chmod +x linuxAIO.sh
    echo "${cyan}Re-execute 'linuxAIO.sh' to continue${nc}"
    clean_exit "0" "Exiting" "true"
    # TODO: Figure out a way to get exec to work
fi

# Changes the working directory to that of where the executed script is
# located
cd "$(dirname "$0")" || {
    echo "${red}Failed to change working directory" >&2
    echo "${cyan}Change your working directory to that of the executed" \
        "script${nc}"
    clean_exit "1" "Exiting" "true"
}
export root_dir="$PWD"
export installer_prep="$root_dir/installer_prep.sh"


#### End of [ Prepping ]
################################################################################
#### [ Functions ]


# Identify the operating system, version number, architecture, bit type (32
# or 64), etc.
detect_sys_info() {
    arch=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        distro="$ID"
        ver="$VERSION_ID"  # Version: x.x.x...
        sver=${ver//.*/}   # Version: x
        pname="$PRETTY_NAME"
        codename="$VERSION_CODENAME"
    else
        distro=$(uname -s)
        if [[ $distro = "Darwin" ]]; then
            ver=$(sw_vers -productVersion)  # macOS version: x.x.x
            sver=${ver%.*}                  # macOS version: x.x
            pname="macOS"
        else
            ver=$(uname -r)
        fi
    fi

    # Identifying bit and architecture type
    case $(uname -m) in
        x86_64) bits="64"; arch="x64" ;;
        i*86)   bits="32"; arch="x86" ;;
        armv*)  bits="32"; arch="?" ;;
        *)      bits="?";  arch="?" ;;
    esac
}

execute_master_installer() {
    supported=true

    curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_master_installer.sh \
            -o nadeko_master_installer.sh || {
        echo "${red}Failed to download 'nadeko_master_installer.sh'${nc}" >&2
        clean_exit "1" "Exiting" "true"
    }
    sudo chmod +x nadeko_master_installer.sh && ./nadeko_master_installer.sh || {
        echo "${red}Failed to execute 'nadeko_master_installer.sh'${nc}" >&2
        clean_exit "1" "Exiting" "true"
    }
}


#### End of [ Functions ]
################################################################################
#### [ Main ]


clear -x

detect_sys_info
export distro sver ver arch bits codename
export -f clean_exit

echo "SYSTEM INFO"
echo "Bit Type: $bits"
echo "Architecture: $arch"
printf "Distro: "
if [[ -n $pname ]]; then echo "$pname"; else echo "$distro"; fi
echo "Distro Version: $ver"
echo ""

if [[ $distro = "ubuntu" ]]; then
    # B.1. Forcing 64 bit architecture
    if [[ $bits = 64 ]]; then
        case "$ver" in
            16.04) execute_master_installer ;;
            18.04) execute_master_installer ;;
            20.04) execute_master_installer ;;
            *)     supported=false ;;
        esac
    else
        supported=false
    fi
elif [[ $distro = "debian" ]]; then
    if [[ $bits = 64 ]]; then  # B.1.
        case "$sver" in
            9)  execute_master_installer ;;
            10) execute_master_installer ;;
            *)  supported=false ;;
        esac
    else
        supported=false
    fi
elif [[ $distro = "linuxmint" ]]; then
    if [[ $bits = 64 ]]; then  # B.1.
        case "$sver" in
            18) execute_master_installer ;;
            19) execute_master_installer ;;
            20) execute_master_installer ;;
            *)  supported=false ;;
        esac
    else
        supported=false
    fi
elif [[ $distro = "Darwin" ]]; then
    case "$sver" in
        10.14) execute_master_installer ;;
        10.15) execute_master_installer ;;
        11.0)  execute_master_installer ;;
        *)     supported=false ;;
    esac
else
    supported=false
fi

if [[ $supported = false ]]; then
    echo "${red}Your operating system/Linux Distribution is not OFFICIALLY" \
        "supported by the installation, setup, and/or use of NadekoBot${nc}" >&2
    read -rp "Would you like to continue with the installation anyways? [y/N] " choice
    choice=$(echo "$choice" | tr '[A-Z]' '[a-z]')
    case "$choice" in
        y|yes) clear -x; execute_master_installer ;;
        n|no)  clean_exit "0" "Exiting" ;;
        *)     clean_exit "0" "Exiting" ;;
    esac
fi


#### End of [ Main ]
################################################################################
