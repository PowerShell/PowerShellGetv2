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
# culture="en-US"
ConvertFrom-StringData @'
###PSLOC
    InValidUri=InValid Uri: '{0}'. A sample valid uri: https://www.powershellgallery.com/api/v2/.
    PathDoesNotExist=Path: '{0}' does not exist
    VersionError=MinimumVersion should be less than the maximumVersion. The MinimumVersion or maximumVersion cannot be used with the RequiredVersion in the same command.
    UnexpectedArgument=Unexpected argument type: '{0}'
    SourceNotFound=Source '{0}' not found. Please make sure you register it. 
    CallingFunction="Call a function '{0}'".
###PSLOC
'@
