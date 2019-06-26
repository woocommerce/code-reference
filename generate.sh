#!/bin/sh
# WooCommerce Class API docs generator

# Variables
GENERATOR_VERSION="0.0.1"
WOOCOMMERCE_VERSION=""

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
  echo "./generate.sh -w 3.6.5"
  echo
  echo "Available options:"
  echo "  -h [--help]         Shows help message"
  echo "  -v [--version]      Shows generator version"
  echo "  -w [--woocommerce]  WooCommerce version"
}

output 5 "-------------------------------------------"
output 5 "   WOOCOMMERCE CLASS API DOCS GENERATOR    "
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
    -w|--woocommerce)
      WOOCOMMERCE_VERSION="${2}"
      shift
      ;;
    *)
      output 1 "\"${1}\" is not a valid command. See \"./generate.sh --help\"."
      exit 1;
      ;;
  esac
  shift
done

# Start generation
output 2 "Starting generation process..."
echo

# Bootstrap
rm -rf ./build ./source
mkdir -p ./build ./source

# Install composer packges in case is missing
if [ ! -f "vendor/bin/apigen" ]; then
  output 1 "Composer packages not installed!"
  output 2 "Installing composer packages..."
  composer install
fi

# Clone WooCommerce
output 2 "Cloning WooCommerce ${WOOCOMMERCE_VERSION}..."
echo
git clone --no-checkout --single-branch --depth 1 --branch "${WOOCOMMERCE_VERSION}" https://github.com/woocommerce/woocommerce.git source/woocommerce

# Generate docs
echo
output 2 "Generating API docs..."
echo
./vendor/bin/apigen generate -q
php apigen/hook-docs.php

# Done
echo
output 2 "API docs generated successfully!"
