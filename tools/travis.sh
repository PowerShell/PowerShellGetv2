set -x
ulimit -n 4096

sudo powershell -c "Import-Module ./build.psm1; Install-Dependencies; Invoke-PowerShellGetTest;"
    