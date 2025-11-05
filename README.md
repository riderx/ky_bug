# Ky Bug Reproduction - Issue #689

This project reproduces a bug in ky where POST requests with JSON bodies hang indefinitely on specific Node.js versions.

## Description

**Bug Report**: https://github.com/sindresorhus/ky/issues/689

This bug causes POST/PUT requests with JSON bodies to hang when `await` is used on specific Node.js versions (particularly v18 and v22). The issue is related to how the request body stream is handled.

### Key Observations:
- ✗ **Affected Node.js versions**: 18.x, 22.x
- ✓ **Working Node.js versions**: 20.x (and possibly others)
- ✗ **Broken ky versions**: v1.8.0+ (introduced in PR #651)
- ✓ **Working ky versions**: v1.7.5 and earlier
- Affects POST/PUT requests with JSON bodies
- GET requests are unaffected
- Requests work without `await` but hang with `await`

## Prerequisites

- **Node.js version manager** (required to test across multiple Node.js versions):
  - **nvm** (recommended): https://github.com/nvm-sh/nvm
    - Install: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash`
  - **n** (alternative): https://github.com/tj/n
    - Install: `npm install -g n`
  - The script will automatically detect which one you have installed
- **npm**: Comes with Node.js

## Files

- `index.js` - The test script that makes the ky HTTP request
- `test-node-versions.sh` - Automated script to test across multiple Node.js versions
- `package.json` - Project dependencies

## Quick Start

### Test Current Node.js Version

```bash
# Install dependencies
npm install

# Run the test
npm start
```

If the script hangs, you're running an affected Node.js version!

### Test Across All Node.js Versions

```bash
# Make the script executable
chmod +x test-node-versions.sh

# Run the test suite
./test-node-versions.sh
```

## How the Test Works

The `test-node-versions.sh` script:

1. Iterates through Node.js versions (18.x, 20.x, 22.x)
2. For each Node.js version:
   - Installs the Node.js version using nvm
   - Tests multiple ky versions (1.7.5, 1.8.0, 1.14.0)
3. For each combination:
   - Installs the specific ky version
   - Runs `index.js` with a 30-second timeout
   - Records whether the script:
     - **PASSED**: Completed successfully
     - **HUNG**: Exceeded the timeout (indicates the hanging bug)
     - **FAILED**: Exited with an error
     - **ERROR**: Could not be tested (installation issues)

4. Displays a summary table showing which combinations hang

**Expected results:**
- Node 18.x + ky v1.8.0+: **HUNG** (demonstrates the bug)
- Node 20.x + ky v1.8.0+: **PASSED** (works fine)
- Node 22.x + ky v1.8.0+: **HUNG** (demonstrates the bug)
- Any Node + ky v1.7.5: **PASSED** or **FAILED** (but not HUNG)

## Customization

### Adjust Timeout

Edit `test-node-versions.sh` and change the `TIMEOUT` variable:

```bash
TIMEOUT=30  # Change to desired timeout in seconds
```

### Test Different Node.js Versions

Edit the `NODE_VERSIONS` array in `test-node-versions.sh`:

```bash
NODE_VERSIONS=(
  "18.0.0"
  "20.0.0"
  "22.0.0"
  # Add more versions here
)
```

### Test Different Ky Versions

Edit the `KY_VERSIONS` array in `test-node-versions.sh`:

```bash
KY_VERSIONS=(
  "1.7.5"
  "1.8.0"
  "1.14.0"
  # Add more versions here
)
```

### Modify the Test Request

Edit `index.js` to change:
- The URL endpoint
- Request payload
- Headers
- Timeout settings
- Retry configuration

## Expected Behavior

The script should:
- Make an HTTP POST request
- Either succeed with a response or fail with an error
- Respect the 10-second timeout specified in the code

## Bug Behavior

On affected Node.js versions:
- The script hangs indefinitely
- No response or error is returned
- The timeout is not respected
- Process must be manually killed

## Interpreting Results

After running `./test-node-versions.sh`, you'll see a summary table like:

```
Node.js         | ky 1.7.5   | ky 1.8.0   | ky 1.14.0
----------------|------------|------------|------------
v18.0.0         | PASSED     | HUNG       | HUNG
v20.0.0         | PASSED     | PASSED     | PASSED
v22.0.0         | PASSED     | HUNG       | HUNG
```

Legend:
- ✓ **Green PASSED**: Combination works correctly
- ✗ **Red HUNG**: Combination exhibits the hanging bug
- ✗ **Yellow FAILED**: Combination has other errors
- ? **Yellow ERROR**: Combination could not be tested

## Troubleshooting

### Node version manager not found

The script supports both `nvm` and `n`. If you get an error:

**For nvm users**: Make sure nvm is loaded in your shell:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Add this to your `~/.bashrc` or `~/.zshrc` for persistence.

**For n users**: Make sure `n` is installed globally:

```bash
npm install -g n
```

### Permission denied

Make the script executable:

```bash
chmod +x test-node-versions.sh
```

### Timeout not working

The script uses the `timeout` command, which should be available on macOS and Linux. If not available, install it:

- macOS: `brew install coreutils` (provides `gtimeout`, update script to use `gtimeout`)
- Linux: Usually pre-installed

## Contributing

If you find this bug affects additional Node.js or ky versions, please:
1. Update the `NODE_VERSIONS` and/or `KY_VERSIONS` arrays
2. Run the test
3. Document your findings in the GitHub issue

## Related Issues

- Main issue: https://github.com/sindresorhus/ky/issues/689
- Root cause PR: https://github.com/sindresorhus/ky/pull/651
- Original issue that PR tried to fix: https://github.com/sindresorhus/ky/issues/650

## License

ISC
