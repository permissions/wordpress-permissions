#!/bin/bash

##
# Based from script found at: https://wordpress.org/node/244924
#
# See README or code below for usage
##

# Help menu.
print_help() {
cat <<-HELP

This script is used to fix permissions of a Wordpress installation
you need to provide the following arguments:

1) Path to your Wordpress installation.
2) Username of the user that you want to give files/directories ownership.
3) HTTPD group name (defaults to www-data for Apache).

Usage: (sudo) bash ${0##*/} WORDPRESS_PATH WORDPRESS_USER [HTTPD_GROUP]

Example: (sudo) bash ${0##*/} . john
Example: (sudo) bash ${0##*/} . john www-data

HELP
}

# Check for correct number of arguments.
if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
  print_help
	exit 0
fi

# Check for root being the executing user.
# (TODO: Is this really necessary?)
if [ $(id -u) != 0 ]; then
  printf "This script must be run as root.\n"
  exit 1
fi

# Set (default) script arguments.
wordpress_path=${1%/}
wordpress_user=${2}
httpd_group=${3}

wordpress_path=`realpath ${wordpress_path}`

if [ -z "${httpd_group}" ]; then
	httpd_group=www-data
fi

# Basic check to see if this is a valid wordpress install.
if [ -z "${wordpress_path}" ] || [ ! -f "${wordpress_path}/wp-config.php" ]; then
  printf "Error: ${wordpress_path} is not a valid Wordpress path.\n"
  exit 1
fi

# Basic check to see if a valid user is provided.
if [ -z "${wordpress_user}" ] || [ "$(id -un "${wordpress_user}" 2> /dev/null)" != "${wordpress_user}" ]; then
  printf "Error: ${wordpress_user} is not a valid user.\n"
  exit 1
fi

cat <<-CONFIRM
The following settings will be used:

wordpress path: ${wordpress_path}
wordpress user: ${wordpress_user}
HTTPD group: ${httpd_group}

CONFIRM
read -p "Proceed? [y/N]" -n 1 -r
echo

if ! [[ $REPLY =~ ^[Yy]$ ]]; then
	exit 0
fi

cd $wordpress_path
printf "Changing ownership of all contents in ${wordpress_path} to\n"
printf "\tuser:  ${wordpress_user}\n"
printf "\tgroup: ${httpd_group}\n"

chown -R ${wordpress_user}:${httpd_group} .

printf "Changing permissions...\n"
printf "rwxr-x--- on all directories inside ${wordpress_path}\n"
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;

printf "rw-r----- on all files       inside ${wordpress_path}\n"
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

printf "rw-rw---- on all files       inside ${wordpress_path}/wp-content\n"
printf "rwxrwx--- on all directories inside ${wordpress_path}/wp-content\n"
cd ${wordpress_path}/wp-content
find . -type d -exec chmod u=rwx,g=rwx,o= '{}' \;
find . -type f -exec chmod u=rw,g=rw,o= '{}' \;

printf "rw-r----- on all files       inside ${wordpress_path}/wp-content/plugins\n"
cd ${wordpress_path}/wp-content/plugins
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

cd ${wordpress_path}
if [ -d ".git" ]; then
	printf "rwx------ on .git/ directories and files in ${wordpress_path}/.git\n"
	cd ${wordpress_path}
	chmod -R u=rwx,go= .git
	chmod u=rw,go= .gitignore
fi

# printf "rwx------ on various wordpress text files in   ${wordpress_path}\n"
# cd ${wordpress_path}
# chmod u=rw,go= \
# 	CHANGELOG.txt \
# 	COPYRIGHT.txt \
# 	INSTALL.*.txt \
# 	INSTALL.txt \
# 	LICENSE.txt \
# 	MAINTAINERS.txt \
# 	README.txt \
# 	UPGRADE.txt

echo "Done setting proper permissions on files and directories."
