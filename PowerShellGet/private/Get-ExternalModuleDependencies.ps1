function Get-ExternalModuleDependencies
{
    Param (
        [Parameter(Mandatory=$true)]
        [PSModuleInfo]
        $PSModuleInfo
    )

    if($PSModuleInfo.PrivateData -and
       ($PSModuleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable") -and
       $PSModuleInfo.PrivateData["PSData"] -and
       ($PSModuleInfo.PrivateData["PSData"].GetType().ToString() -eq "System.Collections.Hashtable") -and
       $PSModuleInfo.PrivateData.PSData['ExternalModuleDependencies'] -and
       ($PSModuleInfo.PrivateData.PSData['ExternalModuleDependencies'].GetType().ToString() -eq "System.Object[]")
    )
    {
        return $PSModuleInfo.PrivateData.PSData.ExternalModuleDependencies
    }
}