#!/bin/bash

# Set default values
TOKEN=""
REPO_NAME=""
DESCRIPTION="New Project"
PLATFORM="gitlab"
VISIBILITY="false"
README="true"
HELP="false"
INITIAL_COMMIT_MSG="First Blood"
USER_NAME=$(git config user.name)
CLONE="true"
GIT_HELP="false"

# Internal Variables for the script.
RESULT=$?
REMOTE_NAME=""
REPO_SHORT=""
RESPONSE=""
DEFAULT_ERR="Some unknown Error Occured. Response returned as: "
TEMP_FILE_NAME=""
TEMP_RESP=""
CLONE_URL=""
WEB_URL=""
STATUS=""

if [ "$USER_NAME" == "" ]; then
	echo "Git User and Email not set. Use 'git config' for setting user and email"
	exit 1
fi
# Functions for this script

# This function is used for creating the repo on the targeted platform. It accepts the following arguments:
#   1. PLATFORM
#   2. TOKEN
#   3. REPO_NAME
#   4. DESCRIPTION
#   5. VISIBILITY
#   6. README
# The curl command creates a $TEMP_FILE_NAME(temp.json) file during the creation of the repo. This also returns
# access status by the curl which is used for error handling.
create_repo() {
	# local STATUS=""
	local PLTFRM="$1"
	local TKN="$2"
	local RPO_NAME="$3"
	local DESC="$4"
	local VSBLTY="$5"
	local RD_ME="$6"

	local PRVT="true"

	# Previously it was working without this piece of code and this is just a dummy code for filling the private entry for the github.
	if [ "$VSBLTY" == "public" ]; then
		PRVT="false"
	else
		PRVT="true"
	fi

	if [ "$PLTFRM" == "github" ]; then
		echo "Creating Repo at $PLTFRM"
		# The following is the oldest command of the all for the github. Create private repo.
		# STATUS=$(curl -s -o "./$TEMP_FILE_NAME" -w '%{http_code}' -u ":$TKN" https://api.github.com/user/repos -d "{\"name\":\"$RPO_NAME\", \"private\":\"$VSBLTY\", \"auto_init\":\"$RD_ME\",\"description\": \"$DESC\"}")
		# This is best command if works. Previously it was working but stopped working sometime later. Try again with and without visability switch true/false. It does not work now with that switch.
		# STATUS=$(curl -s -o "./$TEMP_FILE_NAME" -w '%{http_code}' -u ":$TKN" https://api.github.com/user/repos -d "{\"name\":\"$RPO_NAME\", \"auto_init\":\"$RD_ME\",\"description\": \"$DESC\", \"visibility\":\"$VSBLTY\"}")

		if [ "$VSBLTY" == "public" ]; then
			STATUS=$(curl -s -o "./$TEMP_FILE_NAME" -w '%{http_code}' -u ":$TKN" https://api.github.com/user/repos -d "{\"name\":\"$RPO_NAME\", \"auto_init\":\"$RD_ME\",\"description\": \"$DESC\"}")
		else
			STATUS=$(curl -s -o "./$TEMP_FILE_NAME" -w '%{http_code}' -u ":$TKN" https://api.github.com/user/repos -d "{\"name\":\"$RPO_NAME\", \"private\":\"$PRVT\", \"auto_init\":\"$RD_ME\",\"description\": \"$DESC\"}")
		fi

	elif [ "$PLTFRM" == "gitlab" ]; then

		echo "Creating Repo at $PLTFRM"
		# Better Method, Collects the results of the responses
		STATUS=$(curl -s -o "./$TEMP_FILE_NAME" -w '%{http_code}' --request POST --header "PRIVATE-TOKEN: $TKN" --header "Content-Type: application/json" --data "{\"name\": \"$RPO_NAME\", \"description\": \"$DESC\", \"path\": \"$RPO_NAME\", \"default_branch\": \"main\", \"visibility\":\"$VSBLTY\", \"initialize_with_readme\": \"$RD_ME\"}" --url 'https://gitlab.com/api/v4/projects/')
	fi
	# echo $STATUS
}

# This function converts the temporary file create by the gitlab/github api access to the pretty printed file
# format to a new file as FILE_NAME.
convert_to_pp_json() {
	local JSON_TXT="$1"
	local FILE_NAME="$2"

	# Format JSON log
	#  cat ./temp.json | python -m json.tool > ./${REPO_SHORT}_REPO.json
	pretty_print "$JSON_TXT" >$FILE_NAME
}

# This function handles different responses from the curl accessess. Function accepts STATUS/RESPONSE, PLATFORM
# and DEFAULT_ERR as arguments.
handle_reponses() {
	local LOCAL_STATUS="$1"
	local PLTFRM="$2"
	local DFLT_ERR="$3"

	if [[ $LOCAL_STATUS == "201" ]]; then
		echo -e "\033[32mRepository created successfully!"
	elif [[ $LOCAL_STATUS == "400" ]]; then
		echo -e "\033[31mError: Repository already exists on $PLTFRM."
	elif [[ $LOCAL_STATUS == "422" ]]; then
		echo -e "\033[31mError: Repository already exists on $PLTFRM or access is not correct."
	elif [[ $LOCAL_STATUS == "401" ]]; then
		echo -e "\033[31mError: Unauthorized. Please check your $PLTFRM access token."
	elif [[ $LOCAL_STATUS == "404" ]]; then
		echo -e "\033[31mError: Not found. Please check the repository name."
	elif [[ $LOCAL_STATUS == "409" ]]; then
		echo -e "\033[31mError: Repository already exists. Please choose a different name."
	elif [[ $LOCAL_STATUS == "429" ]]; then
		echo -e "\033[31mError: Too many requests. Please wait and try again later."
	elif [[ $LOCAL_STATUS == "500" ]]; then
		echo -e "\033[31mError: Internal server error. Please try again later."
	else
		echo -e "\033[31mError: $DFLT_ERR RESPONSE: $LOCAL_STATUS"
	fi
	echo -e "======================================================\033[39m"
	exit 1
}

# This function returns username of the token holder. This function accepts the FILE_NAME of the json file
# for parsing the username from the API response.
get_username() {
	local FILE_NAME=$1
	local USERNAME=""
	local LOGIN_KEY=""

	if [ "$PLATFORM" == "github" ]; then
		LOGIN_KEY="login"
	elif [ "$PLATFORM" == "gitlab" ]; then
		LOGIN_KEY="username"
	fi
	USERNAME=$(cat $FILE_NAME | grep -R $LOGIN_KEY $FILE_NAME | cut -d ':' -f 2 | cut -d ',' -f 1 | cut -d ' ' -f 2 | cut -d '"' -f 2)
	echo $USERNAME
}

# This function returns clone url of the token holder for the created repo. This function accepts the
# FILE_NAME of the json file for parsing the URL from the API response.
get_clone_url() {
	local FILE_NAME=$1
	local CLN_URL=""
	local CLONE_KEY=""

	if [ "$PLATFORM" == "github" ]; then
		CLONE_KEY="ssh_url"
	elif [ "$PLATFORM" == "gitlab" ]; then
		CLONE_KEY="ssh_url_to_repo"
	fi
	CLN_URL=$(cat $FILE_NAME | grep -R $CLONE_KEY $FILE_NAME | cut -d ':' -f 2,3 | cut -d ',' -f 1 | cut -d ' ' -f 2 | cut -d '"' -f 2)
	echo $CLN_URL
}

# This function returns web url of the token holder for the created repo. This function accepts the
# FILE_NAME of the json file for parsing the URL from the API response.
get_web_url() {
	local FILE_NAME=$1
	local WEB_URL=""
	local WEB_KEY=""

	if [ "$PLATFORM" == "github" ]; then
		WEB_KEY="clone_url"
	elif [ "$PLATFORM" == "gitlab" ]; then
		WEB_KEY="web_url"
	fi
	WEB_URL=$(cat $FILE_NAME | grep -m 1 $WEB_KEY $FILE_NAME | cut -d ':' -f 2,3 | cut -d ',' -f 1 | cut -d ' ' -f 2 | cut -d '"' -f 2)
	echo $WEB_URL
}

# This function clones the repo. The function accepts clone url, remote name, backup username, repo name
# platform name as arguments. If the clone url is passed and correct then the fucntion just clones the repo
# otherwise it tries to create its own url to clone the repo. The second case normally comes into play when
# the repo is already available and the script will just try to clone it. It that case the information from
# json response is not available and cannot be accessed. So it needs the alternative approch where the backup
# username is used. This username can also be passed from the commandline.
function clone_repo {
	local CLN_URL="$1"
	local RMOTE_NAME="$2"
	local BAK_USRNAME="$3"
	local RPO_NAME="$4"
	local PLTFRM="$5"

	local HTTPS="https://"
	# Extract the gitlab.com from the remote_name(git@gitlab.com).
	local PLTFRM_URL=$(echo "$RMOTE_NAME" | cut -d '@' -f 2 | cut -d ':' -f 1)

	# Check if the cloning url is provided during the function call
	if [ -z "$CLN_URL" ]; then
		echo -e "\033[31mError: No clone URL provided.\033[39m"
		echo -e "Trying to create URL manually."
		echo "Backup Username is available: $BAK_USRNAME"

		# Checking if the github is tagetted then use the git@github.com:<username>/repo format other use
		# https://gitlab.com/<username>/repo format.
		if [ $PLTFRM == "github" ]; then
			CLN_URL="$RMOTE_NAME:$BAK_USRNAME/$RPO_NAME.git"
		elif [ $PLTFRM == "gitlab" ]; then
			CLN_URL="$HTTPS$PLTFRM_URL/$BAK_USRNAME/$RPO_NAME.git"
		fi

		echo -e "Manually Created URL is: $CLN_URL."
		echo -e "\033[32mTrying again with: $CLN_URL\033[39m"
		git clone "$CLN_URL" && echo -e "\033[32mCloning successful!" || echo -e "\033[31mError: Cloning failed!"
		echo -e "======================================================\033[39m"
	else
		echo -e "\033[32mInfo: Clone URL provided: $CLN_URL\033[39m"
		git clone "$CLN_URL" && echo -e "\033[32mCloning successful!" || echo -e "\033[31mError: Cloning failed!"
		echo -e "======================================================\033[39m"
	fi
}

# This function pretty prints the json txt passed to it as an argument.
function pretty_print() {
	local json=$1
	local indent=$2
	local i=0
	local j=0
	local k=0
	local tab="  "
	local new_json=""
	local indent_level=""

	for ((i = 0; i < ${#json}; i++)); do
		local char="${json:$i:1}"

		if [[ $char == "{" || $char == "[" ]]; then
			new_json="$new_json$char\n"
			((k++))
			indent_level="$indent_level$tab"
			for ((j = 0; j < k; j++)); do
				new_json="$new_json$indent_level"
			done
		elif [[ $char == "}" || $char == "]" ]]; then
			((k--))
			indent_level=""
			for ((j = 0; j < k; j++)); do
				indent_level="$indent_level$tab"
			done
			new_json="$new_json\n$indent_level$char"
		elif [[ $char == "," ]]; then
			new_json="$new_json$char\n"
			for ((j = 0; j < k; j++)); do
				new_json="$new_json$indent_level$tab"
			done
		else
			new_json="$new_json$char"
		fi
	done

	echo -e "$new_json"
}

# Cleanup the temporary files created in the process.
cleaup() {
	local LOCAL_STATUS="$1"
	# if [[ $LOCAL_STATUS == "201" ]]; then
	rm -rf $TEMP_FILE_NAME $FILE_NAME
	# else
	# rm -rf $TEMP_FILE_NAME
	# fi
}

# This function is called in case of help. It prints out the help and command syntax.
usage() {
	echo "Usage: ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p <platform> -v <visibility> -c <clone> -r <readme> -u <backup-username> -h -g"
	echo ""
	echo "Options:"
	echo "  -t <token>            Github or Gitlab token"
	echo "  -n <repo-name>        Repository name"
	echo "  -d <description>      Repository description"
	echo "  -p <platform>         Platform (github or gitlab) default:gitlab"
	echo "  -u <backup-username>  Backup Username in case the cloning url is not captured correctly"
	echo "  -v <visibility>       Repository visibility (true or false) default:false"
	echo "  -c <clone>            Clone Repository (true or false) default:true"
	echo "  -r <readme>           Add README to the repository default:true"
	echo "  -g                    Show git help default:false"
	echo "  -h                    Show this help"
	echo ""
	echo "Examples:"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p github -v false -r"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p gitlab -v true"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p github -v false -r -h"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p gitlab -v true -h"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p gitlab -v true -h -c true"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p gitlab -v true -h -c false"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p gitlab -v true -h -c false"
	echo "  ./auto_repo.sh -t <token> -n <repo-name> -d <description> -p gitlab -v true -h -c false -g"
	echo "  ./auto_repo.sh -t "ghp_qdssOQUn7N" -n "my_cool_repo" -p github -c true"
	echo "  ./auto_repo.sh -t "ghp_qdssOQUn7N" -n "my_cool_repo" -p gitlab"
	echo "  ./auto_repo.sh -t "ghp_qdssOQUn7N" -n "my_cool_repo" -p gitlab -d "My New Project""
	echo "  ./auto_repo.sh -t ghp_qdssOQUn7N -n my_cool_repo"
	# exit 0
}

# This fucntion prints git related help. This is called whenever a -g is passed as argument
git_help() {

	local RMT_NAME="$1"
	local USR_NAME="$2"
	local RPO_NAME="$3"
	echo -e "\033[32m"
	echo '
     _____ _  __          __       __         __           __            
    / ___/(_)/ /_  ___ _ / /___   / /  ___ _ / / ___ ___  / /_ __ __ ___ 
   / (_ // // __/ / _ `// // _ \ / _ \/ _ `// / (_-</ -_)/ __// // // _ \
   \___//_/ \__/  \_, //_/ \___//_.__/\_,_//_/ /___/\__/ \__/ \_,_// .__/
                 /___/                                            /_/    
			    '
	echo -e "\033[33m"
	echo 'git config --global user.name:$USER_NAME"'
	echo "git clone $RMT_NAME:$USR_NAME/$RPO_NAME"

	echo -e "\033[32m"
	echo '
     _____                 __                                                             _  __                  
    / ___/____ ___  ___ _ / /_ ___   ___ _  ___  ___  _    __  ____ ___  ___  ___   ___  (_)/ /_ ___   ____ __ __
   / /__ / __// -_)/ _ `// __// -_) / _ `/ / _ \/ -_)| |/|/ / / __// -_)/ _ \/ _ \ (_-< / // __// _ \ / __// // /
   \___//_/   \__/ \_,_/ \__/ \__/  \_,_/ /_//_/\__/ |__,__/ /_/   \__// .__/\___//___//_/ \__/ \___//_/   \_, / 
                                                                      /_/                                 /___/  
								      '
	echo -e "\033[33m"
	echo " 
cd $RPO_NAME
git switch -c main
touch README.md
git add README.md"
	echo 'git commit -m "add README"
git push -u origin main'

	echo -e "\033[32m"
	echo '
      ___              __                            _      __   _              ___       __    __         
     / _ \ __ __ ___  / /    ___ _ ___    ___ __ __ (_)___ / /_ (_)___  ___ _  / _/___   / /___/ /___  ____
    / ___// // /(_-< / _ \  / _ `// _ \  / -_)\ \ // /(_-</ __// // _ \/ _ `/ / _// _ \ / // _  // -_)/ __/
   /_/    \_,_//___//_//_/  \_,_//_//_/  \__//_\_\/_//___/\__//_//_//_/\_, / /_/  \___//_/ \_,_/ \__//_/   
                                                                      /___/                                
									 '
	echo -e "\033[33m"
	echo "cd existing_folder
git init --initial-branch=main
git remote add origin $RMT_NAME:$USR_NAME/$RPO_NAME.git
git add ."
	echo 'git commit -m "Initial commit"
git push -u origin main'

	echo -e "\033[32m"
	echo '
     ___              __                            _      __   _              _____ _  __                              _  __                  
    / _ \ __ __ ___  / /    ___ _ ___    ___ __ __ (_)___ / /_ (_)___  ___ _  / ___/(_)/ /_  ____ ___  ___  ___   ___  (_)/ /_ ___   ____ __ __
   / ___// // /(_-< / _ \  / _ `// _ \  / -_)\ \ // /(_-</ __// // _ \/ _ `/ / (_ // // __/ / __// -_)/ _ \/ _ \ (_-< / // __// _ \ / __// // /
  /_/    \_,_//___//_//_/  \_,_//_//_/  \__//_\_\/_//___/\__//_//_//_/\_, /  \___//_/ \__/ /_/   \__// .__/\___//___//_/ \__/ \___//_/   \_, / 
                                                                     /___/                          /_/                                 /___/  
								 '
	echo -e "\033[33m"
	echo "cd existing_repo
git remote rename origin old-origin
git remote add origin $RMT_NAME:$USR_NAME/$RPO_NAME.git
git push -u origin --all
git push -u origin --tags"

	echo -e "\033[36m"
	# exit 0
}

# Parse command line arguments
while getopts ":t:n:d:p:v:r:u:c:gh" opt; do
	case $opt in
	t)
		TOKEN="$OPTARG"
		;;
	n)
		REPO_NAME="$OPTARG"
		;;
	d)
		DESCRIPTION="$OPTARG"
		;;
	p)
		PLATFORM="$OPTARG"
		;;
	u)
		USER_NAME="$OPTARG"
		;;
	v)
		VISIBILITY="$OPTARG"
		;;
	# r) README="true"
	r)
		README="$OPTARG"
		;;
	c)
		CLONE="$OPTARG"
		;;
	# h) HELP="true"
	#   ;;
	h)
		HELP="true"
		;;
	g)
		GIT_HELP="true"
		;;
	\?)
		echo "Invalid option -$OPTARG" >&2
		;;
	esac
done

# Capture the remote name
if [ "$PLATFORM" = "github" ]; then
	REMOTE_NAME="git@github.com"
elif [ "$PLATFORM" = "gitlab" ]; then
	REMOTE_NAME="git@gitlab.com"
fi

# Print usage in case parameters are empty
if [ -z "$REPO_NAME" ] || [ -z "$TOKEN" ]; then
	if [ $GIT_HELP == "true" ]; then
		echo "Git help Called"
		git_help "$REMOTE_NAME" "$USER_NAME" "$REPO_NAME"
		exit 0
	elif [ $HELP == "true" ]; then
		usage
		exit 0
	else
		usage
	fi
fi
# Check if the token is provided
if [ -z "$TOKEN" ]; then
	# usage
	echo -e "\033[31mError: Some or all of the parameters are empty\033[39m"
	echo -e "\033[31mError: Please provide a token with -t option\033[39m"
	exit 1
fi

# Check if the repo name is provided
if [ -z "$REPO_NAME" ]; then
	# usage
	echo -e "\033[31mError: Some or all of the parameters are empty\033[39m"
	echo -e "\033[31mError: Please provide a repo name with -n option\033[39m"
	exit 1
fi

# Check if the description is provided
# Not strictly required. If not provided it will be defaulted to New Project
# if [ -z "$DESCRIPTION" ]
# then
#   echo "Please provide a description with -d option"
#   exit 1
# fi

# Check if the platform is valid
if [ "$PLATFORM" != "github" ] && [ "$PLATFORM" != "gitlab" ]; then
	echo -e "\033[31mError: Invalid platform. Please choose either github or gitlab with -p option\033[39m"
	exit 1
fi

# Check if the visibility is valid
if [ "$VISIBILITY" != "true" ] && [ "$VISIBILITY" != "false" ]; then
	echo -e "\033[31mError: Invalid visibility. Please choose either true or false with -v option\033[39m"
	exit 1
else
	if [ "$VISIBILITY" == "false" ]; then
		VISIBILITY="private"
	elif [ "$VISIBILITY" == "true" ]; then
		VISIBILITY="public"
	fi
fi

# Check if the readme is valid
if [ "$README" != "true" ] && [ "$README" != "false" ]; then
	echo -e "\033[31mError: Invalid Readme option. Please choose either true or false with -r option\033[39m"
	exit 1
fi

# Check if the visibility is valid
if [ "$CLONE" != "true" ] && [ "$CLONE" != "false" ]; then
	echo -e "\033[31mError: Invalid Clone Option. Please choose either true or false with -c option\\033[39m"
	exit 1
fi

# Print the values of the variables
echo -e "\033[36m======================================================\033[39m"
# echo "TOKEN: $TOKEN" # Comment the token so the token is not visible.
echo "USER_NAME: $USER_NAME"
echo "REPO_NAME: $REPO_NAME"
echo "DESCRIPTION: $DESCRIPTION"
echo "README: $README"
echo "CLONE: $CLONE"
echo "VISIBILITY: $VISIBILITY"
echo "PLATFORM: $PLATFORM"
# echo "INITIAL_COMMIT_MSG: $INITIAL_COMMIT_MSG"
echo -e "\033[36m======================================================\033[39m"

# # In case space separate words are used for the repo name, the first word will be used
# # when naming the json output file.
REPO_SHORT=$(echo ${REPO_NAME} | cut -d " " -f1)

# File name for the pretty print output of the convert_to_pp_json function.
FILE_NAME=${REPO_SHORT}_REPO.json

# File name for the temporary output file.
TEMP_FILE_NAME=${REPO_SHORT}_temp.json

# Function calls for repo Creation and the response handling
echo -e "\n"
# create_repo sets a STATUS variable for showing the repo creation response.
create_repo $PLATFORM $TOKEN "$REPO_NAME" "$DESCRIPTION" $VISIBILITY $README

# Set the response code from the curl access in the create_repo fucntion
RESPONSE="$STATUS"

# Json response from the curl access created file is copied to the variable.
TEMP_RESP=$(cat $TEMP_FILE_NAME)

# Call to the pretty print function. This function coverts the TEMP_RESP unindeted json txt to formated json txt.
convert_to_pp_json "$TEMP_RESP" "$FILE_NAME"

# Call to handle_response. This function prints appropriate messages in case of success and in case of failure.
handle_reponses "$RESPONSE" "$PLATFORM" "$DEFAULT_ERR"

# USERNAME passed from the command line or in the default settings is backuped. This is used in case the repo
# fails and the API does not return any json response. So the backup username can be used for the creation of
# clone URL in the clone_repo function.
USER_NAME_BAK="$USER_NAME"
USER_NAME=$(get_username $FILE_NAME)

# If the USER_NAME is empty it means that the repo was either available or something else happened due to which
# USER_NAME could not be captured so returning to backup.
if [ -z "$USER_NAME" ]; then
	USER_NAME="$USER_NAME_BAK"
fi

# Call to the get_clone_url and get_web_url functions to get the URLs.
CLONE_URL=$(get_clone_url $FILE_NAME)
WEB_URL=$(get_web_url $FILE_NAME)

# Check if the clone option is set and the repo is required to be cloned else print message. Incase of gitlab
# WEB_URL is passed. CLONE_URL is causing some issues in cloning.
if [ $CLONE == "true" ]; then
	if [ $PLATFORM == "github" ]; then
		clone_repo "$CLONE_URL" "$REMOTE_NAME" "$USER_NAME" "$REPO_NAME" "$PLATFORM"
	elif [ $PLATFORM == "gitlab" ]; then
		clone_repo "$WEB_URL" "$REMOTE_NAME" "$USER_NAME" "$REPO_NAME" "$PLATFORM"
	fi
else
	echo -e "\033[36mInfo: Clone option not set to true so not Cloning the Repo.\033[39m"
fi

# If git help is required and the option -g is set from the commandline the call git_help.
if [ $GIT_HELP == "true" ]; then
	git_help "$REMOTE_NAME" "$USER_NAME" "$REPO_NAME"
fi

cleaup "$STATUS"

# echo -e "\033[31m======================================================\033[39m"
# echo "RESULT: $RESULT"
# echo "REMOTE_NAME: $REMOTE_NAME"
# echo "REPO_SHORT: $REPO_SHORT"
# echo "USER_NAME: $USER_NAME"
# echo "FILE_NAME: $FILE_NAME"
# echo "CLONE_URL: $CLONE_URL"
# echo "WEB_URL: $WEB_URL"
# echo "RESPONSE: $RESPONSE"
# echo -e "\033[31m======================================================\033[39m\n\n"
