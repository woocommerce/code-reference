#!/usr/bin/env bash
set -o errexit # Abort if any command fails
me=$(basename "$0")

help_message="\
Usage: $me -s <version> [<options>]
Deploy generated files to a git branch.

Options:

    -h, --help                      Show this help information.
    -v, --verbose                   Increase verbosity. Useful for debugging.
    -s, --source-version <VERSION>  Source version to build and deploy.
    -r, --github-repo <GITHUB_REPO> GitHub repo with username,
                                         default to \"woocommerce/woocommerce\".
    -p, --default-package <NAME>     Default package name,
                                         default to \"WooCommerce\".
    -e, --allow-empty               Allow deployment of an empty directory.
    -m, --message <MESSAGE>         Specify the message used when committing on
                                         the deploy branch.
    -n, --no-hash                   Don't append the source commit's hash to the
                                         deploy commit's message.
        --build-only                Only build but not push.
        --push-only                 Only push but not build.
        --no-download               Skip download.
"

banner="\
--------------------------------------------------------------------------------
                    WOOCOMMERCE CODE REFERENCE GENERATOR
--------------------------------------------------------------------------------"

# Output colorized strings
#
# Color codes:
# 0 - black
# 1 - red
# 2 - green
# 3 - yellow
# 4 - blue
# 5 - magenta
# 6 - cian
# 7 - white
output() {
    echo "$(tput setaf "$1")$2$(tput sgr0)"
}

parse_args() {
    output 5 "$banner"
    # Set args from a local environment file.
    if [ -e ".env" ]; then
        source .env
    fi

    # Parse arg flags
    # If something is exposed as an environment variable, set/overwrite it
    # here. Otherwise, set/overwrite the internal variable instead.
    while : ; do
        if [[ $1 = "-h" || $1 = "--help" ]]; then
            echo "$help_message"
            exit 0
        elif [[ $1 = "-v" || $1 = "--verbose" ]]; then
            verbose=true
            shift
        elif [[ $1 = "-s" || $1 = "--source-version" ]]; then
            source_version=$2
            shift 2
        elif [[ $1 = "-r" || $1 = "--github-repo" ]]; then
            github_repo=$2
            shift 2
        elif [[ $1 = "-p" || $1 = "--default-package" ]]; then
            default_package=$2
            shift 2
        elif [[ $1 = "-e" || $1 = "--allow-empty" ]]; then
            allow_empty=true
            shift
        elif [[ ( $1 = "-m" || $1 = "--message" ) && -n $2 ]]; then
            commit_message=$2
            shift 2
        elif [[ $1 = "-n" || $1 = "--no-hash" ]]; then
            GIT_DEPLOY_APPEND_HASH=false
            shift
        elif [[ $1 = "--build-only" ]]; then
            build_only=true
            shift
        elif [[ $1 = "--push-only" ]]; then
            push_only=true
            shift
        elif [[ $1 = "--no-download" ]]; then
            run_download=false
            shift
        else
            break
        fi
    done

    if [ ${build_only} ] && [ ${push_only} ]; then
        output 1 "You can only specify one of --build-only or --push-only" >&2
        exit 1
    fi

    if [[ -z $source_version ]]; then
        output 1 "Source version is missing." >&2
        exit 1
    fi

    if [[ -z $github_repo ]]; then
        github_repo="woocommerce/woocommerce"
    fi

    if [[ -z $default_package ]]; then
        default_package="WooCommerce"
    fi

    if [[ -z $run_download ]]; then
        run_download=true
    fi

    # Set internal option vars from the environment and arg flags. All internal
    # vars should be declared here, with sane defaults if applicable.

    # Source directory & target branch.
    project_name=${github_repo##*/}
    deploy_directory=build/api
    deploy_branch=gh-pages

    # If no user identity is already set in the current git environment, use this:
    default_username=${GIT_DEPLOY_USERNAME:-deploy.sh}
    default_email=${GIT_DEPLOY_EMAIL:-}

    # Repository to deploy to. must be readable and writable.
    repo=origin

    # Append commit hash to the end of message by default
    append_hash=${GIT_DEPLOY_APPEND_HASH:-true}
}

download_source() {
    # Bootstrap
    rm -f ./${project_name}.zip
    rm -rf ./${project_name}

    # Install dependencies
    if [ ! -f "vendor/bin/phpdoc" ]; then
        output 1 "PHPDoc missing!"
        output 2 "Installing PHPDoc..."
        composer install
    fi

    # Clone WooCommerce
    output 2 "Download ${project_name}.zip from GitHub release ${source_version}..."
    echo
    curl -LSO# "https://github.com/${github_repo}/releases/download/${source_version}/${project_name}.zip"

    # Check if file exists.
    if [ ! -f "${project_name}.zip" ]; then
        output 1 "Error while download ${project_name}.zip from GitHub release ${source_version}!"
        exit 1
    fi

    # Unzip source code.
    unzip -o "${project_name}.zip" -d .
}

run_build() {
    rm -rf ./build
    mkdir -p ./build

    if $run_download; then
        download_source
    fi
    echo
    output 2 "Generating API docs..."
    echo
    ./vendor/bin/phpdoc run --template="data/templates/${project_name}" --setting=graphs.enabled=true --sourcecode --defaultpackagename=${default_package}
    php generate-hook-docs.php
}

main() {
    enable_expanded_output

    if ! git diff --exit-code --quiet --cached; then
        output 1 Aborting due to uncommitted changes in the index >&2
        return 1
    fi

    commit_hash=` git log -n 1 --format="%H" HEAD`

    # Default commit message uses last title if a custom one is not supplied
    if [[ -z $commit_message ]]; then
        commit_message="Published code reference for $project_name $source_version"
    fi

    # Append hash to commit message unless no hash flag was found
    if [ $append_hash = true ]; then
        commit_message="$commit_message"$'\n\n'"Generated from commit $commit_hash"
    fi

    previous_branch=`git rev-parse --abbrev-ref HEAD`

    if [ ! -d "$deploy_directory" ]; then
        output 1 "Deploy directory '$deploy_directory' does not exist. Aborting." >&2
        return 1
    fi

    # Must use short form of flag in ls for compatibility with macOS and BSD
    if [[ -z `ls -A "$deploy_directory" 2> /dev/null` && -z $allow_empty ]]; then
        output 1 "Deploy directory '$deploy_directory' is empty. Aborting. If you're sure you want to deploy an empty tree, use the --allow-empty / -e flag." >&2
        return 1
    fi

    if git ls-remote --exit-code $repo "refs/heads/$deploy_branch" ; then
        # deploy_branch exists in $repo; make sure we have the latest version

        disable_expanded_output
        git fetch --force $repo $deploy_branch:$deploy_branch
        enable_expanded_output
    fi

    # Check if deploy_branch exists locally
    if git show-ref --verify --quiet "refs/heads/$deploy_branch"
    then incremental_deploy
    else initial_deploy
    fi

    restore_head
}

initial_deploy() {
    git --work-tree "$deploy_directory" checkout --orphan $deploy_branch
    git --work-tree "$deploy_directory" add --all
    commit+push
}

incremental_deploy() {
    # Make deploy_branch the current branch
    git symbolic-ref HEAD refs/heads/$deploy_branch
    # Put the previously committed contents of deploy_branch into the index
    git --work-tree "$deploy_directory" reset --mixed --quiet
    git --work-tree "$deploy_directory" add --all

    set +o errexit
    diff=$(git --work-tree "$deploy_directory" diff --exit-code --quiet HEAD --)$?
    set -o errexit
    case $diff in
        0) echo No changes to files in $deploy_directory. Skipping commit.;;
        1) commit+push;;
        *)
            output 1 git diff exited with code $diff. Aborting. Staying on branch $deploy_branch so you can debug. To switch back to main, use: git symbolic-ref HEAD refs/heads/main && git reset --mixed >&2
            return $diff
            ;;
    esac
}

commit+push() {
    set_user_id
    git --work-tree "$deploy_directory" commit -m "$commit_message"

    disable_expanded_output
    # --quiet is important here to avoid outputting the repo URL, which may contain a secret token
    git push --quiet $repo $deploy_branch
    enable_expanded_output
}

# Echo expanded commands as they are executed (for debugging)
enable_expanded_output() {
    if [ $verbose ]; then
        set -o xtrace
        set +o verbose
    fi
}

# This is used to avoid outputting the repo URL, which may contain a secret token
disable_expanded_output() {
    if [ $verbose ]; then
        set +o xtrace
        set -o verbose
    fi
}

set_user_id() {
    if [[ -z `git config user.name` ]]; then
        git config user.name "$default_username"
    fi
    if [[ -z `git config user.email` ]]; then
        git config user.email "$default_email"
    fi
}

restore_head() {
    if [[ $previous_branch = "HEAD" ]]; then
        # We weren't on any branch before, so just set HEAD back to the commit it was on
        git update-ref --no-deref HEAD $commit_hash $deploy_branch
    else
        git symbolic-ref HEAD refs/heads/$previous_branch
    fi

    git reset --mixed
}

filter() {
    sed -e "s|$repo|\$repo|g"
}

sanitize() {
    "$@" 2> >(filter 1>&2) | filter
}

parse_args "$@"

if [[ ${build_only} ]]; then
    run_build
elif [[ ${push_only} ]]; then
    main "$@"
else
    run_build
    main "$@"
fi
