#!/bin/sh

# Script to test the ky bug across multiple Node.js versions
# Bug #689: POST requests with JSON bodies hang on specific Node.js versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Timeout in seconds (if script runs longer, we consider it "hung")
TIMEOUT=30

# Node.js versions to test (bug is specific to Node 18 and 22)
# Start with known good versions (24, 20) then test problematic ones (18, 22)
NODE_VERSIONS="24.0.0 20.18.0 20.10.0 20.0.0 18.20.0 18.19.0 18.12.0 18.0.0 22.11.0 22.5.0 22.0.0"

# Ky versions to test
KY_VERSIONS="1.7.5 1.8.0 1.14.0"

echo "Testing ky bug (#689) - Node.js version specific issue"
echo "Bug: POST requests with JSON bodies hang on Node 18 & 22"
echo "Timeout set to ${TIMEOUT} seconds per test"
echo "=========================================="
echo ""

# Detect which Node.js version manager is available
NODE_MANAGER=""

if command -v nvm > /dev/null 2>&1 || [ -s "$HOME/.nvm/nvm.sh" ]; then
    NODE_MANAGER="nvm"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    echo "Using nvm (Node Version Manager)"
elif command -v n > /dev/null 2>&1; then
    NODE_MANAGER="n"
    echo "Using n (Node.js version manager)"
else
    printf "${RED}Error: No Node.js version manager found.${NC}\n"
    echo "Please install one of the following:"
    echo "  - nvm: https://github.com/nvm-sh/nvm"
    echo "  - n: https://github.com/tj/n (npm install -g n)"
    exit 1
fi

echo ""

# Detect timeout command (required for this test)
TIMEOUT_CMD=""
if command -v timeout > /dev/null 2>&1; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout > /dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout"
else
    printf "${RED}Error: 'timeout' command not found.${NC}\n"
    echo ""
    echo "This script requires the 'timeout' command to detect hanging processes."
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install coreutils"
    echo "  Linux: Usually pre-installed (part of coreutils)"
    echo ""
    exit 1
fi

echo "Using timeout command: $TIMEOUT_CMD"

# Functions for version management
install_node_version() {
    version=$1
    if [ "$NODE_MANAGER" = "nvm" ]; then
        nvm install "$version" > /dev/null 2>&1
    else
        n "$version" > /dev/null 2>&1
    fi
}

use_node_version() {
    version=$1
    if [ "$NODE_MANAGER" = "nvm" ]; then
        nvm use "$version" > /dev/null 2>&1
    else
        n "$version" > /dev/null 2>&1
    fi
}

# Create results file
RESULTS_FILE="/tmp/ky-test-results-$$.txt"
> "$RESULTS_FILE"

# Test each combination
for node_version in $NODE_VERSIONS; do
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${BLUE}Testing Node.js v${node_version}${NC}\n"
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Install Node.js version if not already installed
    echo "Installing Node.js v${node_version}..."
    if ! install_node_version "$node_version"; then
        printf "${RED}✗ Could not install Node.js v${node_version}${NC}\n"
        for ky_version in $KY_VERSIONS; do
            echo "${node_version}|${ky_version}|ERROR" >> "$RESULTS_FILE"
        done
        echo ""
        continue
    fi

    # Use the specific Node.js version
    use_node_version "$node_version"
    printf "Using Node.js $(node --version)\n"
    echo ""

    # Test each ky version with this Node.js version
    for ky_version in $KY_VERSIONS; do
        printf "${YELLOW}  Testing with ky v${ky_version}...${NC}\n"

        # Install specific ky version
        echo "    Installing ky@${ky_version}..."
        if ! npm install --no-save "ky@${ky_version}" > /tmp/npm-install.log 2>&1; then
            printf "${RED}    ✗ Failed to install ky@${ky_version}${NC}\n"
            echo "${node_version}|${ky_version}|ERROR" >> "$RESULTS_FILE"
            echo ""
            continue
        fi

        # Run the test with timeout
        echo "    Running test (timeout: ${TIMEOUT}s)..."

        if $TIMEOUT_CMD "${TIMEOUT}s" node index.js > /tmp/node-test-output.log 2>&1; then
            # Script completed successfully
            printf "${GREEN}    ✓ PASSED - Script completed successfully${NC}\n"
            echo "${node_version}|${ky_version}|PASSED" >> "$RESULTS_FILE"
        else
            EXIT_CODE=$?
            if [ $EXIT_CODE -eq 124 ] || [ $EXIT_CODE -eq 143 ]; then
                # Timeout occurred - script hung (124 for timeout, 143 for gtimeout)
                printf "${RED}    ✗ HUNG - Script exceeded ${TIMEOUT}s timeout${NC}\n"
                echo "${node_version}|${ky_version}|HUNG" >> "$RESULTS_FILE"
            else
                # Script failed with an error
                printf "${RED}    ✗ FAILED - Script exited with code ${EXIT_CODE}${NC}\n"
                echo "    Last 3 lines of output:"
                tail -3 /tmp/node-test-output.log | sed 's/^/      /'
                echo "${node_version}|${ky_version}|FAILED" >> "$RESULTS_FILE"
            fi
        fi

        echo ""
    done
done

# Print summary table
echo "=========================================="
echo "SUMMARY TABLE"
echo "=========================================="
echo ""

# Print header
printf "%-15s" "Node.js"
for ky_version in $KY_VERSIONS; do
    printf " | %-10s" "ky ${ky_version}"
done
echo ""

# Print separator
printf "%-15s" "---------------"
for ky_version in $KY_VERSIONS; do
    printf " | %-10s" "----------"
done
echo ""

# Print results
for node_version in $NODE_VERSIONS; do
    printf "%-15s" "v${node_version}"
    for ky_version in $KY_VERSIONS; do
        # Find result in file
        result=$(grep "^${node_version}|${ky_version}|" "$RESULTS_FILE" | cut -d'|' -f3)

        case "$result" in
            "PASSED")
                printf " | ${GREEN}%-10s${NC}" "PASSED"
                ;;
            "HUNG")
                printf " | ${RED}%-10s${NC}" "HUNG"
                ;;
            "FAILED")
                printf " | ${YELLOW}%-10s${NC}" "FAILED"
                ;;
            "ERROR")
                printf " | ${YELLOW}%-10s${NC}" "ERROR"
                ;;
            *)
                printf " | %-10s" "?"
                ;;
        esac
    done
    echo ""
done

echo ""
echo "=========================================="
echo "LEGEND"
echo "=========================================="
printf "${GREEN}PASSED${NC}  - Request completed successfully\n"
printf "${RED}HUNG${NC}    - Request hung (demonstrates the bug)\n"
printf "${YELLOW}FAILED${NC}  - Request failed with an error\n"
printf "${YELLOW}ERROR${NC}   - Could not test this combination\n"
echo ""

# Count hung versions
HUNG_COUNT=$(grep -c "|HUNG$" "$RESULTS_FILE" || true)

# Clean up
rm -f "$RESULTS_FILE"

if [ "$HUNG_COUNT" -gt 0 ]; then
    printf "${RED}Found ${HUNG_COUNT} combinations that hang!${NC}\n"
    exit 1
else
    printf "${GREEN}No hanging issues detected.${NC}\n"
    exit 0
fi
