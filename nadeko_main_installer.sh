#!/bin/bash
#
# The master/main installer for Linux Distributions.
#
# Comment key:
#   A.1. - Return to prevent further code execution.
#   B.1. - Prevent the code from running if the option is disabled.
#
########################################################################################
#### [ Variables ]


# Store process id of 'nadeko_main_installer.sh', in case it needs to be manually
# killed by a sub/child script.
export _NADEKO_MASTER_INSTALLER_PID=$$
## To be exported.
_NADEKO_SERVICE_NAME="nadeko.service"
_NADEKO_SERVICE="/etc/systemd/system/$_NADEKO_SERVICE_NAME"

# Indicates which major version of dotnet is required.
req_dotnet_version=6


#### End of [ Variables ]
########################################################################################
#### [ Functions ]


_GET_SERVICE_STATUS() {
    ####
    # Function Info: Store the status of NadekoBot's service, inside of
    #                $_NADEKO_SERVICE_STATUS.
    ####

    _NADEKO_SERVICE_STATUS=$(systemctl is-active "$_NADEKO_SERVICE_NAME")
}

_STOP_SERVICE() {
    ####
    # Function Info: Stops NadekoBot's service.
    #
    # Parameters:
    #   $1 - optional
    #       True when the function should output text indicating if the service has been
    #       stopped or is currently not running.
    ####

    if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
        echo "Stopping '$_NADEKO_SERVICE_NAME'..."
        sudo systemctl stop "$_NADEKO_SERVICE_NAME" || {
            echo "${_RED}Failed to stop '$_NADEKO_SERVICE_NAME'" >&2
            echo "${_CYAN}You will need to restart '$_NADEKO_SERVICE_NAME' to apply" \
                "any updates to NadekoBot${_NC}"
            return 1
        }
        if [[ $1 = true ]]; then
            echo -e "\n${_GREEN}NadekoBot has been stopped${_NC}"
        fi
    else
        if [[ $1 = true ]]; then
            echo -e "\n${_CYAN}NadekoBot is not currently running${_NC}"
        fi
    fi
}

_FOLLOW_SERVICE_LOGS() {
    ####
    # Function Info: Display the logs from 'nadeko.server' as they are created.
    ####

    (
        trap 'exit 130' SIGINT
        sudo journalctl -f -u "$_NADEKO_SERVICE_NAME"  | ccze -A
    )
}

_WATCH_SERVICE_LOGS() {
    ####
    # Function Info: Output additional information to go along with the output of the
    #                function '_FOLLOW_SERVICE_LOGS'.
    #
    # Parameters:
    #   $1 - required
    #       Indicates if the function was called from one of the runner scripts or from
    #       within the master installer.
    ####

    if [[ $1 = "runner" ]]; then
        echo "Displaying '$_NADEKO_SERVICE_NAME' startup logs, live..."
    else
        echo "Watching '$_NADEKO_SERVICE_NAME' logs, live..."
    fi

    echo "${_CYAN}To stop displaying the startup logs:"
    echo "1) Press 'Ctrl' + 'C'${_NC}"
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
    ####

    case "$1" in
        3) return 0 ;;
        *) exit "$1" ;;
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
    ####
    # Function Info: Provide the reason(s) for why one or more options are disabled.
    ####

    echo "${_CYAN}Reasons for the disabled option:"

    if (! hash dotnet \
            || ! hash redis-server \
            || (! hash python && (! hash python3 && ! hash python-is-python3)) \
            || ! "$ccze_installed" \
            || [[ $dotnet_version != "$req_dotnet_version" ]]) &>/dev/null; then
        echo "  One or more prerequisites are not installed"
        echo "    Use option 6 to install prerequisites"
    fi

    if [[ -d nadekobot ]]; then
        if [[ ! -f nadekobot/output/creds.yml ]]; then
            echo "  The 'creds.yml' could not be found"
            echo "    Refer to the following link for help: https://nadekobot.readthedocs.io/en/v3/creds-guide/"
        fi
    else
        echo "  NadekoBot could not be found"
        echo "    Use option 1 to download NadekoBot"
    fi

    echo "$_NC"
}


#### End of [ Functions ]
########################################################################################
#### [ Main ]


printf "%sWelcome to the NadekoBot installer\n\n" "$_CLRLN"

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
    option_five_disabled=false
    option_five_text="5. Display '$_NADEKO_SERVICE_NAME' logs in follow mode"
    ## Option 7.
    option_seven_disabled=false
    option_seven_text="7. Back up important files"


    #### End of [[ Temporary Variables ]]
    ####################################################################################
    #### [[ Variable Checks ]]
    #### The following variables re-check the status, existence, etc., of some service
    #### or program, that has the possiblity of changing every time the while loop runs.


    if hash dotnet &>/dev/null; then
        ## Dotnet version.
        dotnet_version=$(dotnet --version)     # Version: x.x.x
        dotnet_version=${dotnet_version//.*/}  # Version: x
    fi


    #### End of [[ Variable Checks ]]
    ####################################################################################
    #### [[ Main continued ]]


    # Get the current status of $_NADEKO_SERVICE_NAME.
    _GET_SERVICE_STATUS

    # Determines if $ccze_installed is true or false, or in otherwords, if ccze is
    # installed or not.
    hash_ccze

    ## Disable option 1 if any of the following tools are not installed.
    if (! hash dotnet \
            || ! hash redis-server \
            || ! hash python3 \
            || ! "$ccze_installed" \
            || [[ ${dotnet_version:-false} != "$req_dotnet_version" ]]) &>/dev/null; then
        option_one_disabled=true
        option_one_text="${_GREY}${option_one_text}${disabled_option}${_NC}"
    fi

    ## Disable options 2, 3, and 5 if any of the tools in the previous if statement are
    ## not installed, or none of the specified directories/files could be found.
    if "$option_one_disabled" || [[ ! -f nadekobot/output/creds.yml ]]; then
        ## Options 2 & 3.
        option_two_and_three_disabled=true
        option_two_text="${_GREY}${option_two_text}${disabled_option}${_NC}"
        option_three_text="${_GREY}${option_three_text}${disabled_option}${_NC}"
        ## Option 5.
        option_five_disabled=true
        option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"

        if [[ ! -d nadekobot ]]; then
            ## Option 7.
            option_seven_disabled=true
            option_seven_text="${_GREY}${option_seven_text}${disabled_option}${_NC}"
        fi
    ## Options 2 and 3 remain enabled, if 'NadekoRun.sh' exists.
    elif [[ -f NadekoRun.sh ]]; then
        ## Option 5 remains enabled, if NadekoBot's service is running.
        if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
            run_mode_status=" ${_GREEN}(Running in this mode)${_NC}"
        ## Disable option 5 if NadekoBot's service NOT running.
        elif [[ $_NADEKO_SERVICE_STATUS = "inactive" ]]; then
            ## Option 5.
            option_five_disabled=true
            option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"

            run_mode_status=" ${_YELLOW}(Set up to run in this mode)${_NC}"
        ## Disable option 5.
        else
            ## Option 5.
            option_five_disabled=true
            option_five_text="${_GREY}${option_five_text}${disabled_option_v2}${_NC}"

            run_mode_status=" ${_YELLOW}(Status unknown)${_NC}"
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
    echo "$option_seven_text"
    echo "8. Exit"
    read -r choice
    case "$choice" in
        1)
            ## B.1.
            if "$option_one_disabled"; then
                clear -x
                echo "${_RED}Option 1 is currently disabled${_NC}"
                disabled_reasons
                continue
            fi

            export _NADEKO_SERVICE
            export -f _STOP_SERVICE
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS

            _DOWNLOAD_SCRIPT "nadeko_latest_installer.sh" "true"
            clear -x
            ./nadeko_latest_installer.sh || exit_code_actions "$?"

            (
                trap 'clean_up "130" "Exiting" "true" "4"' SIGINT
                trap 'clean_up "143" "Exiting" "true" "4"' SIGTERM
                trap 'clean_up "148" "Exiting" "true" "4"' SIGTSTP

                # TODO: Figure out way to kill previous execution of the installer, possibly
                #       an array of PIDs and the 'clean_up()' function. This way, cleaning
                #       up and exiting text doesn't print duplicates.
                # Execute the newly downloaded version of 'installer_prep.sh', so that all
                # changes are applied.
                exec "$_INSTALLER_PREP"
                exit 4
            )
            ;;
        2|3)
            ## B.1.
            if "$option_two_and_three_disabled"; then
                clear -x
                echo "${_RED}Option $choice is currently disabled${_NC}"
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
            _STOP_SERVICE "true"
            read -rp "Press [Enter] to return to the installer menu"
            clear -x
            ;;
        5)
            clear -x
            ## B.1.
            if "$option_five_disabled"; then
                echo "${_RED}Option 5 is currently disabled${_NC}"
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
            ## B.1.
            if "$option_seven_disabled"; then
                clear -x
                echo "${_RED}Option 7 is currently disabled${_NC}"
                disabled_reasons
                continue
            fi

            _DOWNLOAD_SCRIPT "file_backup.sh"
            clear -x
            ./file_backup.sh || exit_code_actions "$?"
            clear -x
            ;;
        8)
            exit 0
            ;;
        *)
            clear -x
            echo "${_RED}Invalid input: '$choice' is not a valid option${_NC}" >&2
            echo ""
            ;;
    esac


    #### End of [[ Main continued ]]
    ####################################################################################
done


#### End of [ Main ]
########################################################################################
