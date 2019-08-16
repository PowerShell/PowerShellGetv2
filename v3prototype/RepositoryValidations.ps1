#####################################
### Register-PSResourceRepository ###
#####################################
# Should register the PowerShell Gallery
Register-PSRepository -PSGallery

<<<<<<< HEAD
# Should register the repository 'TestRepo'
Register-PSResourceRepository 'TestRepo' 'www.testrepo.com'

# Should register the repository 'TestRepo'
Register-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com'

# Should register the repository 'TestRepo' as trusted, priority should be set to 0
Register-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com' -Trusted

# Should register the repository 'TestRepo' with a priority of 2
Register-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com' -Priority 2

### Repositories
# Should register the repositories 'TestRepo1', 'TestRepo2', 'PSGallery'
Register-PSResourceRepository -Repositories @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; Credential = $cred }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)

# Should return the repositories 'TestRepo1', 'TestRepo2', 'PSGallery'
$repos = @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
=======
# Should register the repository "TestRepo"
Register-PSResourceRepository "TestRepo" "www.testrepo.com"

# Should register the repository "TestRepo"
Register-PSResourceRepository -name "TestRepo" -url "www.testrepo.com"

# Should register the repository "TestRepo" as trusted, priority should be set to 0
Register-PSResourceRepository -name "TestRepo" -url "www.testrepo.com" -Trusted

# Should register the repository "TestRepo" with a priority of 2
Register-PSResourceRepository -name "TestRepo" -url "www.testrepo.com" -Priority 2

### Repositories
# Should register the repositories "TestRepo1", "TestRepo2", "PSGallery"
Register-PSResourceRepository -Repositories @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; Credential = $cred }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)

# Should return the repositories "TestRepo1", "TestRepo2", "PSGallery"
$repos = @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37
    @{ Default = $true; Trusted = $true }
)
$repos | Register-PSResourceRepository



################################
### Get-PSResourceRepository ###
################################
# Should return all repositories
Get-PSResourceRepository

<<<<<<< HEAD
# Should return the repository 'TestRepo'
Get-PSResourceRepository 'TestRepo'

# Should return the repository 'TestRepo'
Get-PSResourceRepository -name 'TestRepo'

# Should return the repositories 'TestRepo1', 'TestRepo2', 'TestRepo3'
Get-PSResourceRepository 'TestRepo1', 'TestRepo2', 'TestRepo3'

# Should return the repositories 'TestRepo1', 'TestRepo2', 'TestRepo3'
Get-PSResourceRepository -name 'TestRepo1', 'TestRepo2', 'TestRepo3'

# Should return the repository 'TestRepo'
'TestRepo1' | Get-PSResourceRepository

# Should return the repositories 'TestRepo1', 'TestRepo2', 'TestRepo3'
'TestRepo1', 'TestRepo2', 'TestRepo3' | Get-PSResourceRepository
=======
# Should return the repository "TestRepo"
Get-PSResourceRepository "TestRepo"

# Should return the repository "TestRepo"
Get-PSResourceRepository -name "TestRepo"

# Should return the repositories "TestRepo1", "TestRepo2", "TestRepo3"
Get-PSResourceRepository "TestRepo1", "TestRepo2", "TestRepo3"

# Should return the repositories "TestRepo1", "TestRepo2", "TestRepo3"
Get-PSResourceRepository -name "TestRepo1", "TestRepo2", "TestRepo3"

# Should return the repository "TestRepo"
"TestRepo1" | Get-PSResourceRepository

# Should return the repositories "TestRepo1", "TestRepo2", "TestRepo3"
"TestRepo1", "TestRepo2", "TestRepo3" | Get-PSResourceRepository
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37



################################
### Set-PSResourceRepository ###
################################
<<<<<<< HEAD
# Should set the repository 'TestRepo' to the url 'www.testrepo.com'
Set-PSResourceRepository 'TestRepo' 'www.testrepo.com'

# Should set the repository 'TestRepo' to the url 'www.testrepo.com'
Set-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com'

# Should set the repository 'TestRepo' to trusted, with a priority of 0
Set-PSResourceRepository 'TestRepo' -Trusted

# Should set the repository 'TestRepo' with a priority of 2
Set-PSResourceRepository 'TestRepo' 'www.testrepo.com' -Priority 2

# Should set the repository 'TestRepo'
'TestRepo1' | Set-PSResourceRepository -url 'www.testrepo.com'

### Repositories
# Should set the repositories 'TestRepo1', 'TestRepo2', 'PSGallery' to trusted, with a priority of 0
Set-PSResourceRepository -Repositories @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)

# Should return the repositories 'TestRepo1', 'TestRepo2', 'PSGallery'
$repos = @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
=======
# Should set the repository "TestRepo" to the url "www.testrepo.com"
Set-PSResourceRepository "TestRepo" "www.testrepo.com"

# Should set the repository "TestRepo" to the url "www.testrepo.com"
Set-PSResourceRepository -name "TestRepo" -url "www.testrepo.com"

# Should set the repository "TestRepo" to trusted, with a priority of 0
Set-PSResourceRepository "TestRepo" -Trusted

# Should set the repository "TestRepo" with a priority of 2
Set-PSResourceRepository "TestRepo" "www.testrepo.com" -Priority 2

# Should set the repository "TestRepo"
"TestRepo1" | Set-PSResourceRepository -url "www.testrepo.com"

### Repositories
# Should set the repositories "TestRepo1", "TestRepo2", "PSGallery" to trusted, with a priority of 0
Set-PSResourceRepository -Repositories @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)

# Should return the repositories "TestRepo1", "TestRepo2", "PSGallery"
$repos = @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37
    @{ Default = $true; Trusted = $true }
)
$repos | Set-PSResourceRepository



#######################################
### Unregister-PSResourceRepository ###
#######################################
<<<<<<< HEAD
# Should unregister the repository 'TestRepo'
Unregister-PSResourceRepository -name 'TestRepo'

# Should unregister the repositories 'TestRepo1', 'TestRepo2', 'TestRepo3'
Unregister-PSResourceRepository -name 'TestRepo1', 'TestRepo2', 'TestRepo3'

# Should unregister the repository 'TestRepo'
'TestRepo1' | Unregister-PSResourceRepository

# Should unregister the repositories 'TestRepo1', 'TestRepo2', 'TestRepo3'
'TestRepo1', 'TestRepo2', 'TestRepo3' | Unregister-PSResourceRepository
=======
# Should unregister the repository "TestRepo"
Unregister-PSResourceRepository -name "TestRepo"

# Should unregister the repositories "TestRepo1", "TestRepo2", "TestRepo3"
Unregister-PSResourceRepository -name "TestRepo1", "TestRepo2", "TestRepo3"

# Should unregister the repository "TestRepo"
"TestRepo1" | Unregister-PSResourceRepository

# Should unregister the repositories "TestRepo1", "TestRepo2", "TestRepo3"
"TestRepo1", "TestRepo2", "TestRepo3" | Unregister-PSResourceRepository
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37
