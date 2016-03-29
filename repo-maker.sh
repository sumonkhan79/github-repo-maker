#!/bin/bash
function commentry(){
	# :P
	if [[ "$1" != "" ]]; then
		echo -n "(leave empty for using $1): "
	else
		echo -n ": "
	fi
	
}

function typer(){
	# Again :P
	local o speedFactor textToType OPTIND
	speedFactor=0.02;
	textToType=;

	while getopts "ns:t:" o 2>/dev/null;
	do
		case "$o" in
			n)
				newLine="N"
				;;
			s)
				speedFactor="$OPTARG"
				;;
			t)
				textToType="$OPTARG"
				;;
			[?])
				echo "Usage: typer [-n] [-s speedFactor] [-t textToType]"
				;;
		esac
	done

	echo "$textToType" | egrep -o ".?" | while read character
	do
		if [[ "$character" == "" ]]; then
			character=" "
		fi
		echo -n "$character"
		sleep "$speedFactor"
	done

	# Check new line argument 
	if [[ "$newLine" != "N" ]]; then
		echo ""
	fi
}

function setupGit(){

	# Save password in git cache for 1 hour
	git config --global credential.helper 'cache --timeout 3600'
	
	# Use global config if exists
	globalUserName=`git config --global user.name`
	globalEmailId=`git config --global user.email`

	echo -n "Enter your github username " && commentry "$globalUserName"
	read username
	if [[ "$username" == "" ]]; then
		username="$globalUserName"
	fi

	echo -n "Enter your github emailid " && commentry "$globalEmailId"
	read email
	if [[ "$email" == "" ]]; then
		email="$globalEmailId"
	fi 

	echo "Enter your github authentication token (used for creating remote repositories): "
	token=""
	while [[ "$token" == "" ]]; do
		read token
		if [[ "$token" == "" ]]; then
			echo "Please enter correct token: "
		fi
	done

	echo "Please enter the commit message for the first commit (default is 'init commit'): "
	read message
	if [[ "$message" == "" ]]; then
		message='init commit'
	fi

	echo "Do you want auto init (i.e. create README files for empty folders), default is No."
	echo -n "(y/N): "
	read auto_init
	if [[ "$auto_init" == "N" || "$auto_init" == "n" ]]; then
		auto_init="false"
	else
		auto_init="true"
	fi
}

function createRepo(){
	repoName=`echo "$1" | tr -cd '[[:alnum:]]' | tr 'A-Z' 'a-z' | sed "s/ /-/g"`
	typer -s 0.03 -t "Creating repository $repoName, please wait..."
	git init >/dev/null
	git config user.name "$username"
	git config user.email "$email"
	git remote add origin https://"$username"@github.com/"$username"/"$repoName"
	curl -s -i -H "Authorization: token $token" -d "{ \"name\": \"$repoName\",\"auto_init\": $auto_init, \"private\": false }" https://api.github.com/user/repos -k | grep html_url >/dev/null 2>/dev/null 
	if [[ "$?" -eq 0 ]]; then
		echo "Successfully created $repoName"
		if [[ "$?" -eq 0 ]]; then
			if [[ "$auto_init" == "true" ]]; then
				git pull origin master
			fi
			git add .
			git commit -m "$message"
			git push origin master
			echo "Repository $repoName successfully created"
			# clear
			# return 0
		else
			echo "Error while creating repository remotely"
			echo "Please check your authentication token"
			# return 1
		fi
	else
		echo "Unable to create repo, please report bug @ https://github.com/ironmaniiith/git-repo-maker..."
	fi
}

echo "Enter the directory name (leave blank current directory)"
read DIR
if [[ "$DIR" == "" ]]; then
	DIR=`pwd`
fi

ls -ld "$DIR" 2>/dev/null | egrep "^d" >/dev/null;

status="$?"

if [[ "$status" -eq 0 || "$DIR" == "" ]] ; then
	setupGit
	cd "$DIR"
	ls -d */ | while read directory;
	do
		cd "$directory"
		ls -dl .git >/dev/null 2>/dev/null
		if [[ "$?" -ne 0 ]]; then
			createRepo "$directory"
		else
			echo "The folder $directory is already a git repo, ignoring..."
		fi
		cd "$DIR"
	done
	exit 0
else
	echo "Error: No such directory."
	exit 1
fi
