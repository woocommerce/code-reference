#!/bin/sh
# WooCommerce Class API docs generator

# Variables
GENERATOR_VERSION="0.1.0"
SOURCE_VERSION=""
GITHUB_REPO="woocommerce/woocommerce"

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

# Output error message.
help_output() {
  echo "Usage: ./generate.sh [options]"
  echo
  echo "Generate WooCommerce Class API docs."
  echo
  echo "Examples:"
  echo "./generate.sh -w 4.3.1"
  echo
  echo "Available options:"
  echo "  -h [--help]           Shows help message"
  echo "  -v [--version]        Shows generator version"
  echo "  -s [--source-version] Version of the source code to release"
  echo "  -r [--github-repo]    GitHub repo with username, default to \"woocommerce/woocommerce\""
}

output 5 "-------------------------------------------"
output 5 "   WOOCOMMERCE CODE REFERENCE GENERATOR    "
output 5 "-------------------------------------------"

# Display help message when no option is used.
if [ -z "$1" ]; then
  help_output
fi

# Set user options
while [ ! $# -eq 0 ]; do
  case "$1" in
    -h|--help)
      help_output
      exit 0
      ;;
    -v|--version)
      echo "Version ${GENERATOR_VERSION}"
      exit 0
      ;;
    -s|--source-version)
      if [ -z "$2" ]; then
        output 1 "Please enter a source version, e.g \"4.3.1\""
        exit 1
      fi
      SOURCE_VERSION="${2}"
      shift
      ;;
    -r|--github-repo)
      if [ -z "$2" ]; then
        output 1 "Please enter a GitHub repository name, e.g \"woocommerce/woocommerce\""
        exit 1
      fi
      GITHUB_REPO="${2}"
      shift
      ;;
    *)
      output 1 "\"${1}\" is not a valid command. See \"./generate.sh --help\"."
      exit 1
      ;;
  esac
  shift
done

if [ -z "${SOURCE_VERSION}" ]; then
  output 1 "Please enter a source version, e.g ./generate.sh -s 4.3.1."
  exit 1
fi

# Start generation
output 2 "Starting generation process..."
echo

# Bootstrap
rm -f woocommerce.zip
rm -rf ./build ./woocommerce
mkdir -p ./build

# Install dependencies
if [ ! -f "vendor/bin/phpdoc" ]; then
  output 1 "PHPDoc missing!"
  output 2 "Installing PHPDoc..."
  composer install
fi

# Clone WooCommerce
output 2 "Download WooCommerce ${SOURCE_VERSION}..."
echo
curl -LSO# "https://github.com/woocommerce/woocommerce/releases/download/${SOURCE_VERSION}/woocommerce.zip"

# Check if file exists.
if [ ! -f "woocommerce.zip" ]; then
  output 1 "Error while download WooCommerce ${SOURCE_VERSION} from GitHub releases!"
  exit 1
fi

# Unzip source code.
unzip -o "woocommerce.zip" -d .

# Generate docs
echo
output 2 "Generating API docs..."
echo
./vendor/bin/phpdoc run --template="data/templates/woocommerce"

# Done
echo
output 2 "API docs generated successfully!"
