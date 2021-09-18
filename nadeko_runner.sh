#!/bin/bash
#
# Start NadekoBot in the specified run mode, on Linux distributions.
#
# Comment key for '[letter].[number].':
#   A.1. - Used in conjunction with the 'systemctl' command.
#   B.1. - Used in the text output.
#
########################################################################################
#### [ Variables ]

# The contents of NadekoBot's service.
nadeko_service_content="[Unit]
Description=NadekoBot service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$_WORKING_DIR
ExecStart=/bin/bash NadekoRun.sh
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=NadekoBot

[Install]
WantedBy=multi-user.target"

### Indicate which actions ('disable' or 'enable') to be performed on NadekoBot's
### service.
if [[ $_CODENAME = "NadekoRun" ]]; then
    dis_en_lower="disable"    # A.1.
    dis_en_upper="Disabling"  # B.1.
else
    dis_en_lower="enable"    # A.1.
    dis_en_upper="Enabling"  # B.1.
fi


#### End of [ Variables ]
########################################################################################
#### [ Main ]


# Check if the service exists.
if [[ -f $_NADEKO_SERVICE ]]; then echo "Updating '$_NADEKO_SERVICE_NAME'..."
else                               echo "Creating '$_NADEKO_SERVICE_NAME'..."
fi

# Create/update the service.
echo "$nadeko_service_content" | sudo tee "$_NADEKO_SERVICE" &>/dev/null \
        && sudo systemctl daemon-reload || {
    echo "${_RED}Failed to create '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
    read -rp "Press [Enter] to return to the installer menu"
    exit 4
}

## $dis_en_lower the service.
echo "$dis_en_upper '$_NADEKO_SERVICE_NAME'..."
sudo systemctl "$dis_en_lower" "$_NADEKO_SERVICE_NAME" || {
    echo "${_RED}Failed to $dis_en_lower '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must be ${dis_en_lower}d in order to use this run mode$_NC"
    read -rp "Press [Enter] to return to the installer menu"
    exit 4
}

# Check if 'NadekoRun.sh' exists.
if [[ -f NadekoRun.sh ]]; then echo "Updating 'NadekoRun.sh'..."
## Create 'NadekoRun.sh' if it doesn't exist.
else
    echo "Creating 'NadekoRun.sh'..."
    touch NadekoRun.sh
    sudo chmod +x NadekoRun.sh
fi

## Add the code required to run NadekoBot in the background, to 'NadekoRun.sh'.
if [[ $_CODENAME = "NadekoRun" ]]; then
    printf '%s\n' \
        "#!bin/bash" \
        "" \
        "_code_name_=\"NadekoRun\"" \
        "" \
        "echo \"Running NadekoBot in the background\"" \
        "youtube-dl -U" \
        "" \
        "echo \"Starting NadekoBot...\"" \
        "cd $_WORKING_DIR/nadekobot/output" \
        "dotnet NadekoBot.dll" \
        "echo \"Stopping NadekoBot...\"" \
        "cd $_WORKING_DIR" > NadekoRun.sh
## Add code required to run NadekoBot in the background with auto restart, to
## 'NadekoRun.sh'.
else
    printf '%s\n' \
        "#!/bin/bash" \
        "" \
        "_code_name_=\"NadekoRunAR\"" \
        "" \
        "echo \"\"" \
        "echo \"Running NadekoBot in the background with auto restart\"" \
        "youtube-dl -U" \
        "" \
        "echo \"Starting NadekoBot...\"" \
        "" \
        "while true; do" \
        "    {" \
        "        cd $_WORKING_DIR/nadekobot/output" \
        "        dotnet NadekoBot.dll" \
        "    # If a non-zero exit code is produced, exit this script." \
        "    } || {" \
        "        error_code=\"\$?\"" \
        "        echo \"An error occurred when trying to start NadekBot\"" \
        "        echo \"EXIT CODE: \$?\"" \
        "        exit \"\$error_code\"" \
        "    }" \
        "" \
        "    youtube-dl -U" \
        "    echo \"Restarting NadekoBot...\"" \
        "done" \
        "" \
        "echo \"Stopping NadekoBot...\"" > NadekoRun.sh
fi

## Restart the service if it is currently running.
if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
    echo "Restarting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl restart "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to restart '$_NADEKO_SERVICE_NAME'$_NC" >&2
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
## Start the service if it is NOT currently running.
else
    echo "Starting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl start "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to start '$_NADEKO_SERVICE_NAME'$_NC" >&2
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
fi

_WATCH_SERVICE_LOGS "runner"


#### End of [ Variables ]
########################################################################################
