
function Register-PSResourceRepository {
    [OutputType([void])]
    [Cmdletbinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'NameParameterSet')]
    Param
    (
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $URL,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [PSCredential]
        $Credential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'PSGalleryParameterSet')]
        [Switch]
        $PSGallery,

        [Parameter(ParameterSetName = 'RepositoriesParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Repositories,

        [Parameter()]
        [Switch]
        $Trusted,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter()]
        [ValidateRange(0, 50)]
        [int]
        $Priority = 25
    )

    begin { }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'PSGalleryParameterSet') {
            if (-not $PSGallery) {
                return
            }

            #Register PSGallery
            write-verbose -message "Successfully registered the repository PSGallery"
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'RepositoriesParameterSet') {
            foreach ($repo in $Repositories) {

                if ($pscmdlet.ShouldProcess($repo)) {
                    #Register each repository in the hashtable
                    $PSResourceRepository = [PSCustomObject] @{
                        Name     = $repo.Name
                        URL      = $repo.URL
                        Trusted  = $repo.Trusted
                        Priority = $repo.Priority
                    }

                    write-verbose -message "Successfully registered the repository $repo"
                }
            }
        }
        else {
            if ($pscmdlet.ShouldProcess($Name)) {

                #Register the repository
                $PSResourceRepository = [PSCustomObject] @{
                    Name     = $Name
                    URL      = $URL
                    Trusted  = $Trusted
                    Priority = $Priority
                }

                write-verbose -message "Successfully registered the repository $Name"
            }
        }
    }
    end { }
}


function Get-PSResourceRepository {
    [OutputType([PSCustomObject])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name
    )

    begin { }
    process {
        foreach ($n in $name) {
            if ($pscmdlet.ShouldProcess($n)) {

                #Find and return repository
                $PSResourceRepository = [PSCustomObject] @{
                    Name     = $Name
                    URL      = "placeholder-for-url"
                    Trusted  = "placeholder-for-trusted"
                    Priority = "placeholder-for-priority"
                }

                return $PSResourceRepository
            }
        }
    }
    end { }
}


function Set-PSResourceRepository {
    [OutputType([void])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $URL,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [Switch]
        $Trusted,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'RepositoriesParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Repositories,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, 50)]
        [int]
        $Priority
    )


    begin { }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'RepositoriesParameterSet') {

            foreach ($repo in $Repositories) {
                if ($pscmdlet.ShouldProcess($repo)) {

                    $repository = Get-PSResourceRepository

                    if (-not $repository) {
                        ThrowError -ExceptionMessage "This repository could not be found."
                        return
                    }

                    #Set repository properties
                    $PSResourceRepository = [PSCustomObject] @{
                        Name     = $repo.Name
                        URL      = $repo.URL
                        Trusted  = $repo.Trusted
                        Priority = $repo.Priority
                    }
                    write-verbose -message "Successfully set the $repo repository."
                }
            }
        }
        else {
            if ($pscmdlet.ShouldProcess($Name)) {

                $repository = Get-PSResourceRepository

                if (-not $repository) {
                    ThrowError -ExceptionMessage "This repository could not be found."
                    return
                }

                #Set repository properties
                $PSResourceRepository = [PSCustomObject] @{
                    Name               = $Name
                    URL                = $URL
                    InstallationPolicy = $InstallationPolicy
                    Priority           = $Priority
                }

                write-verbose "Successfully set the $Name repository."
            }
        }
    }
    end { }
}


function Unregister-PSResourceRepository {
    [OutputType([void])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name
    )

    begin { }
    process {
        foreach ($n in $name) {
            if ($pscmdlet.ShouldProcess($n)) {
                #Unregister the each repository
                write-verbose -message "Successfully unregistered $n"
            }
        }
    }
    end { }
}
