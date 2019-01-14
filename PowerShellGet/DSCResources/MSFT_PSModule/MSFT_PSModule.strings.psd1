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
ConvertFrom-StringData @'
###PSLOC
    FailtoUninstall=Failed to uninstall the module '{0}'. Message: {1} 
    FailtoInstall=Failed to install the module '{0}'. Message: {1}       
    InDesiredState=Resource '{0}' is in the desired state
    NotInDesiredState=Resource '{0}' is not in the desired state
    ModuleFound=Module '{0}' found in the node
    ModuleNotFound=Module '{0}' not found in the node
    ModuleWithRightPropertyNotFound=Module '{0}' with the right version or other properties not found in the node. Message: {1}
    ModuleNotFoundInRepository=Module '{0}' with the right version or other properties not found in the repository. Message: {1}                    
    StartGetModule=Begin invoking get-module '{0}'
    StartFindModule=Begin invoking find-module '{0}'
    StartInstallModule=Begin invoking install-module '{0}' version '{1}' from '{2}' repository
    StartUnInstallModule=Begin invoking uninstall of the module '{0}'
    InstalledSuccess=Successfully installed the module '{0}'
    UnInstalledSuccess=Successfully uninstalled the module '{0}'    
    VersionMismatch=The installed Module '{0}' has the version: '{1}'
    RepositoryMismatch=The installed Module '{0}' is from '{1}' repository
    FoundModulePath=Found the module path:'{0}'
    MultipleModuleFound=Total: '{0}' modules found with the same name. Please use RequiredVersion for filtering. Message: {1}
    InstallationPolicyWarning=You are installing the module '{0}' from an untrusted repository' {1}'. Your current InstallationPolicy is '{2}'. If you trust the repository, set the policy to "Trusted". "Untrusted" otherwise.
    InstallationPolicyFailed=Failed in the installation policy. Your current InstallationPolicy is '{0}' and the repository is '{1}'. If you trust the repository, set the policy to "Trusted". "Untrusted" otherwise.
###PSLOC

'@

