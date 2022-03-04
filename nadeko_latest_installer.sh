#!/bin/bash
#
# Downloads and updates NadekoBot.
#
########################################################################################
#### [ Variables ]


current_creds="nadekobot/output/creds.yml"
new_creds="nadekobot_tmp/nadekobot/output/creds.yml"
current_database="nadekobot/output/data/NadekoBot.db"
new_database="nadekobot_tmp/nadekobot/output/data/NadekoBot.db"
current_data="nadekobot/output/data"
new_data="nadekobot_tmp/nadekobot/output/data"
export DOTNET_CLI_TELEMETRY_OPTOUT=1  # Used when compiling code.


#### End of [ Variables ]
########################################################################################
#### [ Main ]


read -rp "We will now download/update NadekoBot. Press [Enter] to begin."

########################################################################################
#### [[ Stop service ]]


## Stop the service if it's currently running.
if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
    nadeko_service_active=true
    _STOP_SERVICE "false"
fi


#### End of [[ Stop service ]]
########################################################################################
#### [[ Create Backup, Then Update ]]


## Create a temporary folder to download NadekoBot into.
mkdir nadekobot_tmp
cd nadekobot_tmp || {
    echo "${_RED}Failed to change working directory$_NC" >&2
    exit 1
}

echo "Downloading NadekoBot into 'nadekobot_tmp'..."
# Download NadekoBot from a specified branch/tag.
git clone -b "$_NADEKO_INSTALL_VERSION" --recursive --depth 1 \
        https://gitlab.com/Kwoth/nadekobot || {
    echo "${_RED}Failed to download NadekoBot$_NC" >&2
    exit 1
}

# If '/tmp/NuGetScratch' exists...
if [[ -d /tmp/NuGetScratch ]]; then
    echo "Modifying ownership of '/tmp/NuGetScratch' and '/home/$USER/.nuget'"
    # Due to permission errors cropping up every now and then, especially when the
    # installer is executed with root privilege, it's necessary to make sure that
    # '/tmp/NuGetScratch' and '/home/$USER/.nuget' are owned by the user that the
    # installer is currently being run under.
    sudo chown -R "$USER":"$USER" /tmp/NuGetScratch /home/"$USER"/.nuget || {
        echo "${_RED}Failed to to modify the ownership of '/tmp/NuGetScratch' and/or" \
            "'/home/$USER/.nuget'...$_NC" >&2
        exit 1
    }
fi

echo "Building NadekoBot..."
{
    cd nadekobot \
    && dotnet restore -f --no-cache \
    && dotnet build src/NadekoBot/NadekoBot.csproj -c Release -o output/ \
    && cd "$_WORKING_DIR"
} || {
    echo "${_RED}Failed to build NadekoBot$_NC" >&2
    exit 1
}

## Move credentials, database, and other data to the new version of NadekoBot.
if [[ -d nadekobot_tmp/nadekobot && -d nadekobot ]]; then
    echo "Copying 'creds.yml' to the new version..."
    cp -f "$current_creds" "$new_creds" &>/dev/null
    echo "Copying database to the new version..."
    cp -RT "$current_database" "$new_database" &>/dev/null

    echo "Copying other data to the new version..."

    ### On update, strings will be new version, user will have to manually re-add his
    ### strings after each update as updates may cause big number of strings to become
    ### obsolete, changed, etc. However, old user's strings will be backed up to
    ### strings_old.

    ## Backup new strings to reverse rewrite.
    rm -rf "$new_data"/strings_new &>/dev/null
    mv -fT "$new_data"/strings "$new_data"/strings_new

    ## Delete old string backups.
    rm -rf "$current_data"/strings_old &>/dev/null
    rm -rf "$current_data"/strings_new &>/dev/null

    # Backup new aliases to reverse rewrite.
    mv -f "$new_data"/aliases.yml "$new_data"/aliases_new.yml

    # Move old data folder contents (and overwrite).
    cp -RT "$current_data" "$new_data"

    # Backup old aliases.
    mv -f "$new_data"/aliases.yml "$new_data"/aliases_old.yml
    # Restore new aliases.
    mv -f "$new_data"/aliases_new.yml "$new_data"/aliases.yml

    # Backup old strings.
    mv -f "$new_data"/strings "$new_data"/strings_old
    # Restore new strings.
    mv -f "$new_data"/strings_new "$new_data"/strings

    rm -rf nadekobot_old && mv -f nadekobot nadekobot_old
fi

mv nadekobot_tmp/nadekobot . && rmdir nadekobot_tmp


#### End of [[ Create Backup, Then Update ]]
########################################################################################
#### [[ Clean Up and Present Results ]]


echo -e "\n${_GREEN}Finished downloading/updating NadekoBot$_NC"

if [[ $nadeko_service_active ]]; then
    echo "${_CYAN}NOTE: '$_NADEKO_SERVICE_NAME' was stopped to update NadekoBot and" \
        "needs to be started using one of the run modes in the installer menu$_NC"
fi

read -rp "Press [Enter] to apply any existing changes to the installers"


#### End of [[ Clean Up and Present Results ]]
########################################################################################

#### End of [ Main ]
########################################################################################
