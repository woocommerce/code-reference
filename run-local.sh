#!/usr/bin/env bash
set -o errexit # Abort if any command fails

echo "🚀 WooCommerce Code Reference Generator - Local Development"
echo "=========================================================="

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

# Check if woocommerce directory exists in current directory
if [ -d "woocommerce" ]; then
    echo "📁 Found existing woocommerce directory in current project."
    WOOCOMMERCE_DIR="woocommerce"
else
    # Prompt user for WooCommerce directory
    echo "📁 Please provide the path to your WooCommerce directory."
    echo "Example: /Users/YourUserName/woocommerce/plugins/woocommerce"
    echo ""
    read -p "Enter WooCommerce directory path: " WOOCOMMERCE_DIR

    # Check if directory exists
    if [ ! -d "$WOOCOMMERCE_DIR" ]; then
        echo "❌ WooCommerce plugin directory not found at: $WOOCOMMERCE_DIR"
        echo "   Please check the path and try again."
        exit 1
    fi
fi

echo "📁 Using WooCommerce plugin directory: $WOOCOMMERCE_DIR"

# Only copy files if we're using an external path (not the existing woocommerce directory)
if [ "$WOOCOMMERCE_DIR" != "woocommerce" ]; then
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

# Clean up any existing build
if [ -d "build" ]; then
    echo "🧹 Cleaning up existing build..."
    rm -rf build
fi

echo "🔧 Generating documentation from local WooCommerce source..."
echo ""

# Run PHPDocumentor directly with the local source
./vendor/bin/phpdoc run \
    --template="data/templates/woocommerce" \
    --sourcecode \
    --defaultpackagename="WooCommerce"

# Generate hook documentation AFTER PHPDocumentor completes
echo "🔧 Generating hook documentation..."
php generate-hook-docs.php

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
