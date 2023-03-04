
function log { echo "`date +\"%Y-%m-%dT%H:%M:%SZ\"`: $@"; }
function warn { >&2 echo "`date +\"%Y-%m-%dT%H:%M:%SZ\"`: $@"; }

function error {
    log "!!! $1"
    exit 1
}
