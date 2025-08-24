# ESB vendor module for Home Assistant

Use the upstream script only, keep credentials in `secrets`, publish JSON to Home Assistant `www`. No need to change directory at any time, the scripts resolve their own paths.

## Prerequisites

- git and python3 installed
- A Home Assistant project with `docker/homeassistant/www` present

## Folder layout

```
esb/
  requirements.txt
  .env.example
  bootstrap.sh
  run_vendor.sh
secrets/
  esb.env
docker/
  homeassistant/
    www/
```

## One time setup

Create the module environment, clone the vendor repository, create env files. You can run this from the repo root or anywhere.

```bash
chmod +x esb/bootstrap.sh esb/run_vendor.sh
./esb/bootstrap.sh
```

Fill secrets.

```bash
$EDITOR secrets/esb.env
# Required keys:
# ESB_MPRN=YOUR_11_DIGIT_MPRN
# ESB_USER=you@example.com
# ESB_PASS=your_password
```

Optional, pin a specific vendor commit or tag.

```bash
$EDITOR esb/.env
# Set VENDOR_REF to a commit sha or tag, leave empty to use main
# Also set HA_WWW_DIR if your Home Assistant www path is not the default
```

## Run the fetch

The `run_vendor.sh` script automates the original `esb-smart-meter-reader.py` from the vendor repository. The original script requires you to manually edit the file to add your credentials.

To avoid modifying the vendor's code directly (which would make updates difficult), `run_vendor.sh` performs the following steps on each execution:

1.  **Creates a temporary copy** of the vendor script in a `./work` directory.
2.  **"Patches" this copy** by programmatically replacing the placeholder credential lines with the actual secrets from your `secrets/esb.env` file.
3.  **Forces JSON output** by modifying the script to print JSON instead of CSV.
4.  **Executes the patched script** to fetch the data.
5.  **Publishes the result** by copying the final JSON to your Home Assistant `www` directory.

This approach keeps your configuration separate from the vendor's code, making the solution robust and easy to maintain.

To run the process:

```bash
./esb/run_vendor.sh
```

Result files

```bash
esb/out/esb_usage_raw.json
docker/homeassistant/www/esb_usage_raw.json
```

Home Assistant serves this at

```bash
http://<ha address>:8123/local/esb_usage_raw.json
```

## Schedule it

Example nightly run at 03:20, adjust path and time.

```cron
20 3 * * * cd /path/to/repo && ./esb/run_vendor.sh >> esb/esb_fetch.log 2>&1
```

## Reset and bootstrap again

Light reset, keeps env files and vendor checkout.

```bash
deactivate



rm -rf esb/.venv
./esb/bootstrap.sh
```

Full reset, simulates a first time clone.

```bash
rm -rf esb/.venv esb/vendor
rm -f esb/.env secrets/esb.env
./esb/bootstrap.sh
```

## Verify

Confirm the environment and vendor script exist after bootstrap.

```bash
test -d esb/.venv && echo "venv present"
test -f esb/vendor/esb-smart-meter-reading-automation/esb-smart-meter-reader.py && echo "vendor present"
```

Run once.

```bash
./esb/run_vendor.sh
```

Deactivate the virtual environment if you activated it manually.

```bash
deactivate
```

## Git ignore

Add these entries to your root `.gitignore`.

```gitignore
esb/.venv/
esb/out/
secrets/
```

## Notes

- The vendor script expects three assignment lines for MPRN, username, password, and a print line for JSON. The runner patches these on each invocation, no manual edits required.
- If the vendor repository changes variable names or output lines, update `run_vendor.sh` once, or pin `VENDOR_REF` to a known good commit in `esb/.env`.
