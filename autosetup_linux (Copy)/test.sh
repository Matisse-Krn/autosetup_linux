#!/bin/bash

ask()       
{
	while true; do
		read -p "$1 (y/n): " -n 1 -r first_reply
		echo
		
		if [[ ! $first_reply =~ ^[YyNn]$ ]]; then
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
			echo
			continue
		fi

		read -p "Please confirm (same answer as before (y/n) : " -n 1 -r second_reply
		echo

		if [[ ! $second_reply =~ ^[YyNn]$ ]]; then
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
			echo
			continue
		fi

		if [[ ! "${first_reply,,}" == "${second_reply,,}" ]]; then
			echo "The answers do not match. Please try again."
			echo
			continue
		fi

		if [[ ${first_reply,,} == "y" ]]; then
			return 0
		else
			return 1
		fi
	done
}

ft_happiness()
{
	if ask "Are you happy ? "; then
		echo
		echo "You are happy !"
	else
		echo
		echo "You are sad..."
	fi
}

ft_happiness
