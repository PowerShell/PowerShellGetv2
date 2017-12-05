set -x
ulimit -n 4096

echo "TRAVIS_EVENT_TYPE value $TRAVIS_EVENT_TYPE"

if [ $TRAVIS_EVENT_TYPE = cron ] || [ $TRAVIS_EVENT_TYPE = api ]; then
    sudo pwsh -c "Import-Module ./tools/build.psm1; Install-Dependencies; Invoke-PowerShellGetTest -IsFullTestPass;"
else
    sudo pwsh -c "Import-Module ./tools/build.psm1; Install-Dependencies; Invoke-PowerShellGetTest;"
fi