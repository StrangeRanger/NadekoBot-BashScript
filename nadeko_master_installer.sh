#!/bin/bash
#
# The master/main installer for macOS and Linux Distributions.
#
# Comment key:
#   A.1. - Return to prevent further code execution.
#   B.1. - Prevent the code from running if the option is disabled.
#
########################################################################################
#### [ Variables ]


# Store process id of 'nadeko_master_installer.sh', in case it needs to be manually
# killed by a sub/child script.
export _NADEKO_MASTER_INSTALLER_PID=$$
## To be exported.
_NADEKO_SERVICE="/etc/systemd/system/nadeko.service"
_NADEKO_SERVICE_NAME="nadeko.service"


#### End of [ Variables ]
########################################################################################
#### [ Functions ]


_SERVICE_ACTIONS() {
    ####
    # Function Info: Actions dealing with the status/state of the NadekoBot's service.
    #
    # Parameters:
    #   $1 - The actions to be performed (i.e. get service status or stop service).
    #   $2 - Dictates whether or not the text indicating that the service has been
    #        stopped or is not running, should be printed to the terminal.
    ####

    ## Save the status of $_NADEKO_SERVICE_NAME to $_NADEKO_SERVICE_STATUS.
    if [[ $1 = "nadeko_service_status" ]]; then
        _NADEKO_SERVICE_STATUS=$(systemctl is-active "$_NADEKO_SERVICE_NAME")
    ## Stops $_NADEKO_SERVICE_NAME if it's actively running.
    elif [[ $1 = "stop_service" ]]; then
        if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
            echo "Stopping '$_NADEKO_SERVICE_NAME'..."
            sudo systemctl stop "$_NADEKO_SERVICE_NAME" || {
                echo "${_RED}Failed to stop '$_NADEKO_SERVICE_NAME'" >&2
                echo "${_CYAN}You will need to restart '$2' to apply any updates" \
                    "to NadekoBot$_NC"
                return 1  # A.1.
            }
            if [[ $2 = true ]]; then
                echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
            fi
        else
            if [[ $2 = true ]]; then
                echo -e "\n${_CYAN}NadekoBot is not currently running$_NC"
            fi
        fi
    fi
}

_FOLLOW_SERVICE_LOGS() {
    ####
    # Function Info: Display the logs from 'nadeko.server' as they are created.
    ####

    (
        trap 'exit' SIGINT
        sudo journalctl -f -u "$_NADEKO_SERVICE_NAME"  | ccze -A
    )
}

_WATCH_SERVICE_LOGS() {
    ####
    # Function Info: Output the general information to go along with the output of the
    #                function '_FOLLOW_SERVICE_LOGS'.
    #
    # Parameters:
    #   $1 - Indicates if the function was called from one of the runner scripts or
    #        from within the master installer.
    ####

    if [[ $1 = "runner" ]]; then
        echo "Displaying '$_NADEKO_SERVICE_NAME' startup logs, live..."
    else
        echo "Watching '$_NADEKO_SERVICE_NAME' logs, live..."
    fi

    echo "${_CYAN}To stop displaying the startup logs:"
    echo "1) Press 'Ctrl' + 'C'$_NC"
    echo ""

    _FOLLOW_SERVICE_LOGS

    if [[ $1 = "runner" ]]; then
        echo -e "\n"
        echo "Please check the logs above to make sure that there aren't any" \
            "errors, and if there are, to resolve whatever issue is causing them"
    fi

    echo -e "\n"
    read -rp "Press [Enter] to return to the installer menu"
}

exit_code_actions() {
    ####
    # Function Info: Depending on the return/exit code from any of the executed scripts,
    #                perform the corresponding/appropriate actions.
    #
    # Parameters:
    #   $1 - Return/exit code.
    #
    # Code Meaning:
    #	1   - Something happened that requires the exit of the entire installer.
    #   127 - When the end-user uses 'CTRL' + 'C' or 'CTRL' + 'Z'.
    ####

    case "$1" in
        1|127) exit "$1" ;;
    esac

}

hash_ccze() {
    ####
    # Function Info: Return whether or not 'ccze' is installed.
    ####

    if hash ccze &>/dev/null; then ccze_installed=true
    else                           ccze_installed=false
    fi
}

disabled_reasons() {
    echo "${_CYAN}Reasons for the disabled option:"

    if (! hash dotnet \
            || ! hash redis-server \
            || (! hash python && (! hash python3 && ! hash python-is-python3)) \
            || [[ $ccze_installed = false ]]) &>/dev/null; then
        echo "  One or more prerequisites are not installed"
    fi

    if [[ ! -f nadekobot/output/creds.yml ]]; then
        echo "  The 'creds.yml' could not be found"
        echo "    Refer to the following link for help: https://nadekobot.readthedocs.io/en/v3/creds-guide/"
    fi

    echo "${_NC}"
}


#### End of [ Functions ]
########################################################################################
#### [ Main ]


echo -e "Welcome to the NadekoBot installer\n"

while true; do
    ####################################################################################
    #### [[ Temporary Variables ]]
    #### The variables below constantly get modified later in the code, and are required
    #### to be reset everytime the while loop is run through.


    ## Disabled option text.
    disabled_option=" (Execute option to display the reason it's disabled)"
    disabled_option_v2=" (Disabled until NadekoBot is running)"
    ## Option 1.
    option_one_disabled=false
    option_one_text="1. Download NadekoBot"
    ## Option 2 & 3.
    option_two_and_three_disabled=false
    option_two_text="2. Run NadekoBot in the background"
    option_three_text="3. Run NadekoBot in the background with auto restart"
    ## Option 5.
    option_five_text="5. Display '$_NADEKO_SERVICE_NAME' logs in follow mode"


    #### End of [[ Temporary Variables ]]
    ####################################################################################
    #### [[ Main continued ]]


    # Get the current status of $_NADEKO_SERVICE_NAME.
    _SERVICE_ACTIONS "nadeko_service_status"

    # Determines if $ccze_installed is true or false.
    hash_ccze

    ## Disable option 1 if any of the following tools are not installed.
    if (! hash dotnet \
            || ! hash redis-server \
            || (! hash python && (! hash python3 && ! hash python-is-python3)) \
            || [[ $ccze_installed = false ]]) &>/dev/null; then
        option_one_disabled=true
        option_one_text="${_GREY}${option_one_text}${disabled_option}${_NC}"
    fi

    ## Disable options 2, 3, and 5 if any of the tools in the previous if statement are
    ## not installed or none of the specified directories/files could be found.
    if [[ ! -f nadekobot/output/creds.yml \
            || $option_one_disabled = true ]]; then
        ## Option 2 & 3.
        option_two_and_three_disabled=true
        option_two_text="${_GREY}${option_two_text}${disabled_option}${_NC}"
        option_three_text="${_GREY}${option_three_text}${disabled_option}${_NC}"
        ## Option 5.
        option_five_disabled=true
        option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"
    ## Options 2 and 3 remain enabled, if 'NadekoRun.sh' exists.
    elif [[ -f NadekoRun.sh ]]; then
        ## Option 5 remains enabled, if NadekoBot's service is running.
        if [[ $_NADEKO_SERVICE_STATUS = "active" \
                || $_NADEKO_SERVICE_STATUS = "running" ]]; then
            run_mode_status=" ${_GREEN}(Running in this mode)$_NC"
        ## Disable option 5 if NadekoBot's service NOT running.
        elif [[ $_NADEKO_SERVICE_STATUS = "inactive" \
                || $_NADEKO_SERVICE_STATUS = "waiting" ]]; then
            ## Option 5.
            option_five_disabled=true
            option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"

            run_mode_status=" ${_YELLOW}(Set up to run in this mode)$_NC"
        ## Disable option 5.
        else
            ## Option 5.
            option_five_disabled=true
            option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"

            run_mode_status=" ${_YELLOW}(Status unknown)$_NC"
        fi

        ## If NadekoBot is running in the background with auto restart...
        if grep -q '_code_name_="NadekoRunAR"' NadekoRun.sh; then
            option_three_text="${option_three_text}${run_mode_status}"
        ## If NadekoBot is running in the background...
        elif grep -q '_code_name_="NadekoRun"' NadekoRun.sh; then
            option_two_text="${option_two_text}${run_mode_status}"
        fi
    ## Options 2 and 3 remained enabled, but option 5 becomes disabled.
    else
        ## Option 5.
        option_five_disabled=true
        option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"
    fi

    echo "$option_one_text"
    echo "$option_two_text"
    echo "$option_three_text"
    echo "4. Stop NadekoBot"
    echo "$option_five_text"
    echo "6. Install prerequisites"
    echo "7. Exit"
    read -r choice
    case "$choice" in
        1)
            ## B.1.
            if [[ $option_one_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 1 is currently disabled$_NC"
                disabled_reasons
                continue
            fi

            export _NADEKO_SERVICE
            export -f _SERVICE_ACTIONS
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS

            _DOWNLOAD_SCRIPT "nadeko_latest_installer.sh" "nadeko_latest_installer.sh"
            clear -x
            ./nadeko_latest_installer.sh || exit_code_actions "$?"

            # Execute the newly downloaded version of 'installer_prep.sh', so that all
            # changes are applied.
            exec "$_INSTALLER_PREP"
            ;;
        2|3)
            ## B.1.
            if [[ $option_two_and_three_disabled = true ]]; then
                clear -x
                echo "${_RED}Option $choice is currently disabled$_NC"
                disabled_reasons
                continue
            fi

            export _NADEKO_SERVICE
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS
            export -f _WATCH_SERVICE_LOGS
            export -f _FOLLOW_SERVICE_LOGS

            _DOWNLOAD_SCRIPT "nadeko_runner.sh"
            clear -x

            # If option 2 was executed...
            if [[ $choice = 2 ]]; then
                export _CODENAME="NadekoRun"
                printf "We will now run NadekoBot in the background. "
            # If option 3 was executed...
            else
                export _CODENAME="NadekoRunAR"
                printf "We will now run NadekoBot in the background with auto restart. "
            fi

            read -rp "Press [Enter] to begin."
            ./nadeko_runner.sh || exit_code_actions "$?"
            clear -x
            ;;
        4)
            clear -x
            read -rp "We will now stop NadekoBot. Press [Enter] to begin."
            _SERVICE_ACTIONS "stop_service" "true"
            read -rp "Press [Enter] to return to the installer menu"
            clear -x
            ;;
        5)
            clear -x
            ## B.1.
            if [[ $option_five_disabled = true ]]; then
                echo "${_RED}Option 5 is currently disabled$_NC"
                echo ""
                continue
            fi

            _WATCH_SERVICE_LOGS "option_five"
            clear -x
            ;;
        6)
            _DOWNLOAD_SCRIPT "prereqs_installer.sh"
            clear -x
            ./prereqs_installer.sh || exit_code_actions "$?"
            clear -x
            ;;
        7)
            exit 0
            ;;
        *)
            clear -x
            echo "${_RED}Invalid input: '$choice' is not a valid option$_NC" >&2
            ;;
    esac


    #### End of [[ Main continued ]]
    ####################################################################################
done


#### End of [ Main ]
########################################################################################
