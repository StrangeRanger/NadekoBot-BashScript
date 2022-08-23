#!/bin/bash
#
# Acts as a transition script from linuxAIO revision 36 to 37. During these changes,
# many of the files were renamed and had the file extension ('.sh') removed.
#
########################################################################################
#### [ Variables ]


## Modify output text color.
cyan="$(printf '\033[0;36m')"
red="$(printf '\033[1;31m')"
nc="$(printf '\033[0m')"

### Identify distro and distro version.
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    distro="$ID"
    ver="$VERSION_ID"  # Version: x.x.x...
    sver=${ver//.*/}   # Version: x
else
    distro=$(uname -s)
    ver=$(uname -r)
fi

## Identify bit and architecture type.
case $(uname -m) in
    x86_64) bits="64"; _ARCH="x64" ;;
    i*86)   bits="32"; _ARCH="x86" ;;
    armv*)  bits="32"; _ARCH="?" ;;
    *)      bits="?";  _ARCH="?" ;;
esac

## Save the values of the current Configuration Variables specified in 'linuxAIO.sh', to
## be set in 'linuxAIO'.
installer_branch=$(grep '^installer_branch=.*' linuxAIO.sh)
installer_branch_found="$?"
nadeko_install_version=$(grep '^export _NADEKO_INSTALL_VERSION=.*' linuxAIO.sh)
nadeko_install_version_found="$?"


#### End of [ Variables ]
########################################################################################
#### [ Functions ]

custom_dotnet() {
    ####
    # Function Info: Ensure that dotnet is set up to work with 'packages.microsoft.com'.
    #                For more information, please visit
    #                https://github.com/dotnet/core/issues/7699.
    ####

    if hash dotnet && [[ ! $(dotnet --version &>/dev/null) ]]; then
        echo "${_YELLOW}While the .NET runtime is installed, the .NET SDK is not${_NC}"
        echo "Uninstalling existing .NET Core 6.0 installation..."
        sudo apt remove dotnet-sdk-6.0 -y
        sudo apt autoremove -y
    fi

    if [[ ! -f /etc/apt/preferences.d/custom-dotnet.pref ]]; then
        echo "Upating prefered .NET Core install method..."

        {
            echo -e "Explanation: https://github.com/dotnet/core/issues/7699" \
                "\nPackage: *" \
                "\nPin: origin \"packages.microsoft.com\"" \
                "\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/custom-dotnet.pref
        } || {
            echo "${_RED}Failed to create" \
                "'/etc/apt/preferences.d/custom-dotnet.pref'${_NC}" >&2
            exit 1
        }

        echo "Reinstalling .NET Core..."
    fi
}

#### End of [ Functions ]
########################################################################################
#### [ Main ]


echo -n "${cyan}There has been some changes that require special intervention. When" \
    "the installer has exited, re-execute the installer, and re-run NadekoBot in your" \
    "chosen run mode. "
read -rp "Press [Enter] to continue.${nc}"

########################################################################################
#### [[ Set Dotnet Preferences ]]


if [[ $bits = 64 ]]; then
    if [[ $distro = "ubuntu" ]]; then
        case "$ver" in
            22.04) custom_dotnet ;;
        esac
    elif [[ $distro = "linuxmint" ]]; then
        case "$sver" in
            21) custom_dotnet ;;
        esac
    fi
fi


#### End of [[ Set Dotnet Preferences ]]
########################################################################################
#### [[ Update Files ]]


curl -O "$_RAW_URL"/linuxAIO && sudo chmod +x linuxAIO
echo "Applying existing configurations to 'linuxAIO'..."

## Set $installer_branch inside of 'linuxAIO'.
[[ $installer_branch_found = 0 ]] \
    && sed -i "s/^installer_branch=.*/$installer_branch/" linuxAIO
## Set $nadeko_install_version inside of 'linuxAIO'.
[[ $nadeko_install_version_found = 0 ]] \
    && sed -i "s/^export _NADEKO_INSTALL_VERSION=.*/$nadeko_install_version/" linuxAIO

echo "Cleaning up..."
[[ -f NadekoRun.sh ]]      && mv NadekoRun.sh NadekoRun
[[ -f installer-prep ]]    && rm installer-prep
[[ -f installer_prep.sh ]] && rm installer_prep.sh

if [[ -f linuxAIO.sh && -f linuxAIO ]]; then
    rm linuxAIO.sh
else
    echo "${red}'linuxAIO.sh' and 'linuxAIO' should exist, but one or both do not.${nc}"
    exit 1
fi


#### End of [[ Update Files ]]
########################################################################################

#### End of [ Main ]
########################################################################################
