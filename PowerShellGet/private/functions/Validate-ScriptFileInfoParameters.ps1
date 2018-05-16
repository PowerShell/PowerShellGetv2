function Validate-ScriptFileInfoParameters
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Parameters
    )

    $hasErrors = $false

    $Parameters.Keys | ForEach-Object {

                                    $parameterName = $_

                                    $parameterValue = $($Parameters[$parameterName])

                                    if("$parameterValue" -match '<#' -or "$parameterValue" -match '#>')
                                    {
                                        $message = $LocalizedData.InvalidParameterValue -f ($parameterValue, $parameterName)
                                        Write-Error -Message $message -ErrorId 'InvalidParameterValue' -Category InvalidArgument

                                        $hasErrors = $true
                                    }
                                }
    return (-not $hasErrors)
}
