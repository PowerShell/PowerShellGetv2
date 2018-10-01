function Get-FindModuleParameterSets {
  
  $manifestData = Get-FindModuleParameterTestManifest 
  $variations = $manifestData.testcasemanifest.Parameters.Variations

  $testParameterSets = @()

  $variations | Foreach-Object {

      $FindModuleInputParameters = [ordered]@{}
      if($_.Name)           {$FindModuleInputParameters['Name']=$_.Name}
      if($_.DscResource)    {$FindModuleInputParameters['DscResource']=$_.DscResource}
      if($_.Command)        {$FindModuleInputParameters['Command']=$_.Command}
      if($_.Includes)       {$FindModuleInputParameters['Includes']=$_.Includes}
      if($_.Tag)            {$FindModuleInputParameters['Tag']=$_.Tag}
      if($_.Filter)         {$FindModuleInputParameters['Filter']=$_.Filter}
      if($_.RequiredVersion){$FindModuleInputParameters['RequiredVersion']=$_.RequiredVersion}
      if($_.MinimumVersion) {$FindModuleInputParameters['MinimumVersion']=$_.MinimumVersion}
      if($_.AllVersions)    {$FindModuleInputParameters['AllVersions']=$_.AllVersions}

      $testParameterSets += @{
                                FindModuleInputParameters = $FindModuleInputParameters
                                PositiveCase = ($_.PositiveCase -ieq "true")
                                FullyQualifiedErrorID = $_.ExpectedFullyQualifiedErrorId
                                ExpectedModuleCount=$_.ExpectedModuleCount
                                ExpectedModuleNames = $_.ExpectedModuleNames
                             }
  }

  $testParameterSets
}

function Get-FindModuleWithSourcesParameterSets {
  
  $manifestData = Get-FindModuleWithSourcesTestManifest
  $variations = $manifestData.testcasemanifest.Parameters.Variations

  $testParameterSets = @()  

  $variations | Foreach-Object {     
    if(-not ($_.Source -like "http*"))
    {
        $testParameterSets += @{   
                                    Name = $_.Name
                                    PositiveCase = ($_.PositiveCase -ieq "true")
                                    FullyQualifiedErrorID = $_.FullyQualifiedErrorID
                                    Source = $_.Source
                                    ExpectedModuleCount=$_.ExpectedModuleCount
                                }
    }
  }

  $testParameterSets
}

function Get-InstallModuleWithSourcesParameterSets {
  
  $manifestData = Get-InstallModuleWithSourcesTestManifest 
  $variations = $manifestData.testcasemanifest.Parameters.Variations

  $testParameterSets = @()  

  $variations | Foreach-Object {     
    if(-not ($_.Source -like "http*"))
    {
        $testParameterSets += @{   
                                Name = $_.Name
                                PositiveCase = ($_.PositiveCase -ieq "true")
                                FullyQualifiedErrorID = $_.FullyQualifiedErrorID
                                Source = $_.Source
                            }
    }
  }

  $testParameterSets
}