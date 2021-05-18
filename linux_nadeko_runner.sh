#!/bin/bash
#
# Start NadekoBot in the specified run mode.
#
# COMMENT '[letter].[number].' KEY INFO:
#   A.1. - Return to prevent further code execution.
#
########################################################################################
#### [ Variables ]

timer=60
# Save the current time and date, which will be used in conjunction with journalctl.
start_time=$(date +"%F %H:%M:%S")
nadeko_service_content="[Unit] 
Description=NadekoBot service

[Service]
ExecStart=/bin/bash $_WORKING_DIR/NadekoRun.sh
User=$USER
Type=simple
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=NadekoBot

[Install]
WantedBy=multi-user.target"

## Decide whether we need to use 'disable' or 'enable', and what tense it should be in.
if [[ $_CODENAME = "NadekoRun" ]]; then
    dis_en_lower="disable"
    dis_en_upper="Disabling"
else
    dis_en_lower="enable"
    dis_en_upper="Enabling"
fi


#### End of [ Variables ]
########################################################################################
#### [ Main ]


if [[ -f $_NADEKO_SERVICE ]]; then
    echo "Updating '$_NADEKO_SERVICE_NAME'..."
else
    echo "Creating '$_NADEKO_SERVICE_NAME'..."
fi

## Create/update '$_NADEKO_SERVICE_NAME'
echo -e "$nadeko_service_content" | sudo tee "$_NADEKO_SERVICE" &>/dev/null &&
        sudo systemctl daemon-reload || {
    echo "${_RED}Failed to create '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
    _CLEAN_EXIT "1" "Exiting"
}

## Disable or enable '$_NADEKO_SERVICE_NAME'.
echo "$dis_en_upper '$_NADEKO_SERVICE_NAME'..."
sudo systemctl "$dis_en_lower" "$_NADEKO_SERVICE_NAME" || {
    echo "${_RED}Failed to $dis_en_lower '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must be ${dis_en_lower}d in order to use this" \
        "run mode$_NC"
    read -rp "Press [Enter] to return to the installer menu"
    return 1  # A.1.
}

# Check if 'NadekoRun.sh' exists.
if [[ -f NadekoRun.sh ]]; then
    echo "Updating 'NadekoRun.sh'..."
else
    echo "Creating 'NadekoRun.sh'..."
    touch NadekoRun.sh
    sudo chmod +x NadekoRun.sh
fi

## Add code to 'NadekoRun.sh' required to run NadekoBot in the background.
if [[ $_CODENAME = "NadekoRun" ]]; then
    echo -e "#!bin/bash \
        \n \
        \n_code_name_=\"NadekoRun\" \
        \n \
        \necho \"Running NadekoBot in the background\" \
        \nyoutube-dl -U \
        \n \
        \ncd $_WORKING_DIR/NadekoBot \
        \ndotnet build -c Release \
        \ncd $_WORKING_DIR/NadekoBot/src/NadekoBot \
        \necho \"Running NadekoBot...\" \
        \ndotnet run -c Release \
        \necho \"Done\" \
        \ncd $_WORKING_DIR \
        \n" > NadekoRun.sh
## Add code to 'NadekoRun.sh' required to run NadekoBot in the background with auto restart.
else
    echo -e "#!/bin/bash \
        \n \
        \n_code_name_=\"NadekoRunAR\" \
        \n \
        \necho \"\" \
        \necho \"Running NadekoBot in the background with auto restart\" \
        \nyoutube-dl -U \
        \n \
        \nsleep 5 \
        \ncd $_WORKING_DIR/NadekoBot \
        \ndotnet build -c Release \
        \n \
        \nwhile true; do \
        \n    cd $_WORKING_DIR/NadekoBot/src/NadekoBot && \
        \n        dotnet run -c Release \
        \n \
        \n    youtube-dl -U \
        \n    sleep 10 \
        \ndone \
        \n \
        \necho \"Stopping NadekoBot\"" > NadekoRun.sh
fi

## Restart '$_NADEKO_SERVICE_NAME' if it is currently active.
if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
    echo "Restarting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl restart "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to restart '$_NADEKO_SERVICE_NAME'$_NC" >&2
        read -rp "Press [Enter] to return to the installer menu"
        return 1  # A.1.
    }
    echo "Waiting 60 seconds for '$_NADEKO_SERVICE_NAME' to restart..."
## Start '$_NADEKO_SERVICE_NAME' if it is NOT currently active.
else
    echo "Starting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl start "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to start '$_NADEKO_SERVICE_NAME'$_NC" >&2
        read -rp "Press [Enter] to return to the installer menu"
        return 1  # A.1.
    }
    echo "Waiting 60 seconds for '$_NADEKO_SERVICE_NAME' to start..."
fi

## Wait in order to give '$_NADEKO_SERVICE_NAME' enough time to (re)start.
while ((timer > 0)); do
    echo -en "$_CLRLN$timer seconds left"
    sleep 1
    ((timer-=1))
done

# NOTE: $_NO_HOSTNAME is purposefully unquoted. Do not quote the variable.
echo -e "\n\n-------- $_NADEKO_SERVICE_NAME startup logs ---------" \
    "\n$(journalctl -q -u nadeko -b $_NO_HOSTNAME -S "$start_time" 2>/dev/null ||
    sudo journalctl -q -u nadeko -b $_NO_HOSTNAME -S "$start_time")" \
    "\n--------- End of $_NADEKO_SERVICE_NAME startup logs --------\n"

echo -e "${_CYAN}Please check the logs above to make sure that there aren't any" \
    "errors, and if there are, to resolve whatever issue is causing them\n"

echo "${_GREEN}NadekoBot is now running in the background$_NC"
read -rp "Press [Enter] to return to the installer menu"
