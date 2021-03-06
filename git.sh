#!/bin/bash
TMP="/tmp/git.tmp"
mkdir -p $TMP
echo "______________________________________________________________________"
echo "| Please enter 'Git user' and 'repository' to find more              |"
echo "| Here is following format: https://github.com/l3m0nqu1z/Git_Checker |"
echo "|                                              \__  ___/ \___  ___/  |"
echo "|                                                 \/         \/      |"
echo "|                                              Git user   Reposotory |"
echo "----------------------------------------------------------------------"
specify_repo() {
read -p "Git user [default: l3m0nqu1z]: " USER
read -p "Its repo [default: Git_Checker]: " REPO
USER=${USER:-l3m0nqu1z}
REPO=${REPO:-Git_Checker}
HTTP_RESPONSE=$(curl -o /dev/null -s -w "%{http_code}\n" https://github.com/$USER/$REPO)
REPOSITORY_URL="https://github.com/$USER/$REPO"
}
check_repo() {
#Vse ravno vhodit pri exit 1 comandy curl
while [[ $HTTP_RESPONSE -ne 200 ]]; do
echo "$HTTP_RESPONSE Error. The repository was not found. Please re-enter "
specify_repo
done
}
download_data() {
curl  \
 -H "Accept: application/vnd.github.v3+json, state: open" \
 https://api.github.com/repos/$USER/$REPO/pulls > $TMP/api
curl \
 -H "Accept: application/vnd.github.v3+json" \
 https://api.github.com/repos/$USER/$REPO/stats/contributors > $TMP/contributors
curl \
 -H "Accept: application/vnd.github.v3+json" \
 https://api.github.com/repos/$USER/$REPO/readme > $TMP/readme
} > /dev/null 2>&1
loading() {
 pid=$!
 spin='-\|/'
 i=0
 while kill -0 $pid 2>/dev/null
 do
   i=$(( (i+1) %4 ))
   printf "\r[${spin:$i:1}] Please wait. Loading repo's data... "
   sleep .1
 done
}
menu() {
printf "\033c"
echo -e "Repository: $REPOSITORY_URL\n"
echo "1. Read README.md"
echo "2. Open Pull Requests(PRs)"
echo -e "3. Most productive contributors\n"
echo "_______________________________"
echo -e "0. Exit\n"
read -p ": " CHOISE
case $CHOISE in
   1)
   repo_readme
   ;;
   2)
   open_pulls_counting
   ;;
   3)
   contributors_stats
   ;;
   0)
   printf "\033c"
   read -p  "Remove all repository data? [Y/n] " REMOVE
      case $REMOVE in
         Y|y|*)
         rm -rf $TMP
         ;;
         N|n)
         exit 0
         ;;
      esac
   ;;
esac
}
repo_readme() {
printf "\033c"
curl $(jq -r '.download_url' $TMP/readme)
echo "____________"
echo -e "0. Main menu\n"
read -p ": " CHOISE
case $CHOISE in
   0)
   menu
   ;;
esac
}
open_pulls_counting() {
printf "\033c"
echo -n "Current open PRs: "
grep -c '"state": "open"' $TMP/api
echo "____________"
echo -e "0. Main menu\n"
read -p ": " CHOISE
case $CHOISE in
   0)
   menu
   ;;
esac
}
contributors_stats() {
printf "\033c"
echo "________________________________________________"
echo "| Commits ||           Contributor             |"
echo "------------------------------------------------"
jq -r '.[] | ["| " + (.total | tostring), "  ||  ", (.author | .login)] | join("\t")' $TMP/contributors | sort -nr -k 2
echo "____________"
echo -e "0. Main menu\n"
read -p ": " CHOISE
case $CHOISE in
   0)
   menu
   ;;
esac
}
#Working steps
specify_repo
check_repo
#checks if folder with repo data exists
if [ -z "$(ls -A $TMP)" ]; then
download_data & loading
fi
menu
