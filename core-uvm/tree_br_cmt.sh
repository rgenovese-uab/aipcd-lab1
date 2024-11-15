#!/usr/bin/env bash

# @title                      Script to obtain the branch name and commit of a git repo and its submodules (tree)
#
# **PROJECT:**                General BSC-CS
#
# **LANGUAGE:**               Bash script
#
# @author                     Noe Bustamante Peralta - noe.bustamante@bsc.es (NB)
#
# @version                    0.1 - First version (NB)

### CURRENT DIRECTORY ###
CURRENT_DIR=$(pwd)
CURRENT_FLDR_NAME=${PWD##*/}

#----------------------------------------------------------------------#
# FUNCTIONS
#----------------------------------------------------------------------#

function git_branch {
  local git_status="$(git status 2> /dev/null)"
  local on_branch="On branch ([^${IFS}]*)"
  local on_commit="HEAD detached at ([^${IFS}]*)"

  if [[ $git_status =~ $on_branch ]]; then
    local branch=${BASH_REMATCH[1]}
    echo ":: ($branch) "
  elif [[ $git_status =~ $on_commit ]]; then
    local commit=${BASH_REMATCH[1]}
    echo ":: ($commit) "
  else
    echo " "
  fi
}

function git_commit {
  local git_commit_h="$(git rev-parse HEAD 2> /dev/null)"
  if [[ ${#git_commit_h} -gt 1 ]]; then
    local git_commit_c=${git_commit_h:0:8}
    echo ":: ($git_commit_c) "
  fi
}

shopt -s nullglob
shopt -s dotglob

dir_count=0
file_count=0

traverse() {
  dir_count=$(($dir_count + 1))
  local directory=$1
  local prefix=$2

  local directory=${directory%/}

  local children=("$directory"/*/)
  local child_count=${#children[@]}

  for idx in "${!children[@]}"; do
    local child=${children[$idx]}
    local child=${child%/}
    bk_dir=$(pwd)
    full_path=${CURRENT_DIR}${child#.}
    cd $full_path
    it_has_git=$(find . -name .git)
    cd $bk_dir

    if [[ ${#it_has_git} -gt 5 ]]; then
      local child_prefix="│   "
      local pointer="├── "

      if [ $idx -eq $((child_count - 1)) ]; then
        pointer="└── "
        child_prefix="    "
      fi

      local child=${child%/}
      full_path_it=${CURRENT_DIR}${child#.}
      cd $full_path_it
      local CURRENT_C=$(git_commit)
      local CURRENT_B=$(git_branch)

      local BASE_TREE="${prefix}${pointer}${child##*/}"
      local sz_aux=${#BASE_TREE}

      if [[ -e ".git" ]]
      then
        printf "${BASE_TREE}"
        printf "%$(( ${first_sep}-${sz_aux} ))s%-25s%s" " " "${CURRENT_B}" "${CURRENT_C}"
        printf '\n'
      else
        printf "${BASE_TREE}"
        printf "%$(( ${first_sep}-${sz_aux} ))s%-25s%s" " " " " " "
        printf '\n'
      fi

      cd $bk_dir

      [ -d "$child" ] &&
        traverse "$child" "${prefix}$child_prefix" ||
        file_count=$((file_count + 1))
    else
      #echo "No gits"
      continue
    fi
  done
}

#----------------------------------------------------------------------#
# MAIN
#----------------------------------------------------------------------#

root="."
[ "$#" -ne 0 ] && root="$1"

CURRENT_C=$(git_commit)
CURRENT_B=$(git_branch)

BASE_TREE=${CURRENT_FLDR_NAME}
first_sep=64
sz_aux=${#BASE_TREE}

printf "${BASE_TREE}" 
printf "%$(( ${first_sep}-${sz_aux} ))s%-25s%s" " " "${CURRENT_B}" "${CURRENT_C}"
printf '\n'

traverse $root ""

shopt -u nullglob
shopt -u dotglob

