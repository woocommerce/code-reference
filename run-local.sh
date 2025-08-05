#!/usr/bin/env bash
set -o errexit # Abort if any command fails

# Change to the script's directory for safety
cd "$(dirname "$0")"

echo "🚀 WooCommerce Code Reference Generator - Local Development"
echo "=========================================================="
echo ""
echo "Usage: ./run-local.sh [source-directory]"
echo "  - If source-directory is provided, use that as WooCommerce source"
echo "  - If no argument provided, use ./woocommerce if it exists, otherwise prompt"
echo ""

# Check if PHP is available
if ! command -v php &> /dev/null; then
    echo "❌ PHP is not installed or not in PATH"
    exit 1
fi

# Check if Composer is available
if ! command -v composer &> /dev/null; then
    echo "❌ Composer is not installed or not in PATH"
    exit 1
fi

# Install dependencies if vendor directory doesn't exist
if [ ! -d "vendor" ]; then
    echo "📦 Installing dependencies..."
    composer install
fi

# Determine WooCommerce directory
if [ $# -eq 1 ]; then
    # Use provided source directory
    WOOCOMMERCE_DIR="$1"
    echo "📁 Using provided source directory: $WOOCOMMERCE_DIR"
elif [ -d "woocommerce" ]; then
    # Use existing woocommerce directory in current project
    WOOCOMMERCE_DIR="woocommerce"
    echo "📁 Found existing woocommerce directory in current project."
else
    # Prompt user for WooCommerce directory
    echo "📁 Please provide the path to your WooCommerce directory."
    echo "Example: /Users/YourUserName/woocommerce/plugins/woocommerce"
    echo ""
    read -p "Enter WooCommerce directory path: " WOOCOMMERCE_DIR
fi

# Check if directory exists
if [ ! -d "$WOOCOMMERCE_DIR" ]; then
    echo "❌ WooCommerce plugin directory not found at: $WOOCOMMERCE_DIR"
    echo "   Please check the path and try again."
    exit 1
fi

echo "📁 Using WooCommerce plugin directory: $WOOCOMMERCE_DIR"

# Copy files if we're using an external path (not the existing woocommerce directory)
if [ "$WOOCOMMERCE_DIR" != "woocommerce" ]; then
    # Always remove existing woocommerce directory when using external source
    if [ -d "woocommerce" ]; then
        echo "🗑️  Removing existing woocommerce directory..."
        rm -rf woocommerce
    fi

    echo "📁 Copying WooCommerce files..."
    mkdir -p woocommerce

    # Copy only the directories we want for documentation
    cp -r "$WOOCOMMERCE_DIR"/includes woocommerce/ 2>/dev/null || true
    cp -r "$WOOCOMMERCE_DIR"/src woocommerce/ 2>/dev/null || true
    cp -r "$WOOCOMMERCE_DIR"/templates woocommerce/ 2>/dev/null || true
else
    echo "📁 Using existing woocommerce directory in project."
fi

# Generate documentation
echo "🔧 Generating documentation from local WooCommerce source..."
echo ""
./deploy.sh --no-download --build-only --source-version 0.0.0

echo ""
echo "✅ Documentation generated successfully!"
echo "📁 Output location: ./build/api/"
echo ""
echo "🌐 Starting local web server for WooCommerce Code Reference..."
echo "📁 Serving from: ./build/api"
echo "🌍 URL: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start PHP development server
php -S localhost:8000 -t build/api
