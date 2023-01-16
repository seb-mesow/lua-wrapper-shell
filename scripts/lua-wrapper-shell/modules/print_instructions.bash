exec_module instruction_list
exec_module config_env_vars

function pi___print_instructions_to_set_this_env_as_default_env() {
    local l_cev___IL \
          l_cev___str
    
    IL___new l_cev___IL
    
    IL___append___raw l_cev___IL \
        "Open the Windows Settings."
    IL___append___raw l_cev___IL \
        "Search for 'environment variable' or the like."
    IL___append___raw l_cev___IL \
        "Open the search result 'Edit the system environment variables' or the like."
    IL___append___raw l_cev___IL \
        "In the already selected tab 'Advanced' click the button 'Environment Variables...'"
    IL___append___other l_cev___IL "\
Important Notes:
Only edit the environment variables in the lower half of the window in the section 'System variables'.

Pay attention to select the whole line with the new value for an environment variable.
(Your text editor or terminal may crop long lines.)"
    
    cev___append_to_IL___instrs_to_set_this_env_as_default_env l_cev___IL
    
    IL___append___raw l_cev___IL \
        "Click the button 'OK' to save the changes."
    IL___append___raw l_cev___IL \
        "Click the button 'OK' to save the changes."
    
    IL___format_manual l_cev___str l_cev___IL
    
    printf "%s" "$l_cev___str"
    
    exit 0
}
