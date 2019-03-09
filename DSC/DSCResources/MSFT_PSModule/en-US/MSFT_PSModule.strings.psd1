#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# culture = "en-US"
ConvertFrom-StringData -StringData @'
    FailToUninstall                 = Failed to uninstall the module '{0}'.
    FailToInstall                   = Failed to install the module '{0}'.
    InDesiredState                  = Resource '{0}' is in the desired state.
    NotInDesiredState               = Resource '{0}' is not in the desired state.
    ModuleFound                     = Module '{0}' is found on the node.
    ModuleNotFound                  = Module '{0}' is not found on the node.
    ModuleWithRightPropertyNotFound = Module '{0}' with the right version or other properties not found in the node.
    ModuleNotFoundInRepository      = Module '{0}' with the right version or other properties not found in the repository.
    StartGetModule                  = Begin invoking Get-Module '{0}'.
    StartFindModule                 = Begin invoking Find-Module '{0}'.
    StartInstallModule              = Begin invoking Install-Module '{0}' version '{1}' from '{2}' repository.
    StartUnInstallModule            = Begin invoking Remove-Item to remove the module '{0}' from the file system.
    InstalledSuccess                = Successfully installed the module '{0}'
    UnInstalledSuccess              = Successfully uninstalled the module '{0}'
    VersionMismatch                 = The installed Module '{0}' has the version: '{1}'
    RepositoryMismatch              = The installed Module '{0}' is from '{1}' repository.
    FoundModulePath                 = Found the module path: '{0}'.
    MultipleModuleFound             = Total: '{0}' modules found with the same name. Please use -RequiredVersion for filtering. Message: {1}
    InstallationPolicyWarning       = You are installing the module '{0}' from an untrusted repository' {1}'. Your current InstallationPolicy is '{2}'. If you trust the repository, set the policy to "Trusted".
    InstallationPolicyFailed        = Failed in the installation policy. Your current InstallationPolicy is '{0}' and the repository is '{1}'. If you trust the repository, set the policy to "Trusted".
    GetTargetResourceMessage        = Getting the current state of the module '{0}'.
    TestTargetResourceMessage       = Determining if the module '{0}' is in the desired state.
'@
