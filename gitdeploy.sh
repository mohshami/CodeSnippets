#!/bin/sh

#Get the location of binary packages
export GIT=$(which git)			#Location of git
export RSYNC=$(which rsync)		#Location of rsync
export GIT_DIR=$(pwd)			#Location of repository

export TMP="/tmp"
export TARFOLDER="${TMP}/git-deploy.$$"

#Sanity checks
if [ ! -f "${GIT}" ]
then
        # Error && exit
        echo "Error: git binary not found"
        exit 255
fi

if [ ! -f "${RSYNC}" ]
then
        # Error && exit
        echo "Error: rsync binary not found"
        exit 255
fi

#Create the folder which will hold the files we need to deploy
if mkdir "$TARFOLDER"
then
else
	# Error && exit
	echo "Error: unable to create temporary tar folder or it already exists."
	exit
fi

#Get the new commit ID and copy the files over to the deployment folder
while read old new ref
do
	#Get the list of changed files
	FILELIST=$($GIT diff-tree --no-commit-id --name-only -r $new)

	# Find branch name
	branch=${ref#"refs/heads/"}
	
	# Check branch name
	if [ -z "${branch}" ]
	then
		echo "Refspec ${ref} is not a branch. Skipped!"
	fi
	
	# Don't attempt to handle deleted branches
	if [ "${new}" = "0000000000000000000000000000000000000000" ]
	then
		# Error && skip branch
		echo "Branch ${branch} deleted. Skipped!"
		continue
	fi

	## Attempt to update
	echo "Branch ${branch} updated. Deploying..."

	# Deploy destination
	dest=$($GIT config --get "deploy.${branch}.uri")
	if [ -z "${dest}" ]
	then
		echo "Error: Destination not set! Deploy failed."
		continue
	fi
	echo "Destination: "${dest}

	# Create directory to archive into
	mkdir "${TARFOLDER}/${branch}"

	# Drop into scratchdir
	cd "${TARFOLDER}/${branch}"
	
	# Set umask
	umask 007

	# Get a copy of worktree
	$GIT archive --format=tar ${new} | tar xf -

	#Apply modifications (copy and delete)
	for file in $FILELIST
	do
		echo $file | $RSYNC -Wa --files-from - --delete "${TARFOLDER}/${branch}/" "${dest}"
	done

	echo ""
	echo $($GIT diff-tree --no-commit-id --name-status -r $new)
	echo ""
done

#Post processing
#Any commands you need to run to set up permissions to clear caches

#Delete temporary folder
rm -rf $TARFOLDER