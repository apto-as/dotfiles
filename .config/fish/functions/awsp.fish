function awsp
    AWS_PROFILE="$AWS_PROFILE" _awsp_prompt
    set selected_profile (cat ~/.awsp)
    set -xU AWS_PROFILE $selected_profile
end

