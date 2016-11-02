set -x
ulimit -n 4096

sudo powershell -c "Import-Module ./tools/build.psm1; Install-Dependencies; Invoke-PowerShellGetTest;"
    