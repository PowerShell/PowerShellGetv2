#
#  Powershell resource provider for DSC tests.
#

$script:Logfile = "$env:SystemRoot\Temp\dsc_ps_test.log"

function Write-Log([string]$logstring)
{
   Add-content $Logfile -value ((Get-date).Tostring() + " " + $logstring)
}

#
# The Get-TargetResource cmdlet.
# 
function Get-TargetResource 
{
     param 
     (      
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [ValidateNotNullOrEmpty()]
        [string]
        $LogPath
     )

    Write-Log "Get. Name: $name"
    $LogPath = "unknown"

    # Add all feature properties to the hash table
    $getTargetResourceResult = @{
                                Name = $feature.Name; 
                                LogPath = $LogPath
                                }
         
    $getTargetResourceResult;
}

#
# The Set-TargetResource cmdlet.
# 
function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName = "FeatureName")]

     param 
     (       
        [parameter(Mandatory=$true, ParameterSetName = "FeatureName")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [ValidateNotNullOrEmpty()]
        [string]
        $LogPath
     )

    Write-Log "Set. Name: $name, LogPath: $LogPath"

}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource 
{
    param 
    (       
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,


        [ValidateNotNullOrEmpty()]
        [string]
        $LogPath
    )
 
    write-verbose "test verbose event"
    Write-debug "test debug event"
    Write-Log "Test. Name: $name, LogPath: $LogPath"

    #if it's running by LCMStopConfigUnitTests then we will do a infinite loop so that we can test the "stop" feature
    if($name -eq "LCMStopConfigUnitTests")
    {
        while($true)
        {
            
        }
    }

    $false
}
