function Get-ScriptCommentHelpInfoString
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Synopsis,

        [Parameter()]
        [string[]]
        $Example,

        [Parameter()]
        [string[]]
        $Inputs,

        [Parameter()]
        [string[]]
        $Outputs,

        [Parameter()]
        [string[]]
        $Notes,

        [Parameter()]
        [string[]]
        $Link,

        [Parameter()]
        [string]
        $Component,

        [Parameter()]
        [string]
        $Role,

        [Parameter()]
        [string]
        $Functionality
    )

    Process
    {
        $ScriptCommentHelpInfoString = "<# `r`n`r`n.DESCRIPTION `r`n $Description `r`n`r`n"

        if("$Synopsis".Trim())
        {
            $ScriptCommentHelpInfoString += ".SYNOPSIS `r`n$Synopsis `r`n`r`n"
        }

        if("$Example".Trim())
        {
            $Example | ForEach-Object {
                           if($_)
                           {
                               $ScriptCommentHelpInfoString += ".EXAMPLE `r`n$_ `r`n`r`n"
                           }
                       }
        }

        if("$Inputs".Trim())
        {
            $Inputs |  ForEach-Object {
                           if($_)
                           {
                               $ScriptCommentHelpInfoString += ".INPUTS `r`n$_ `r`n`r`n"
                           }
                       }
        }

        if("$Outputs".Trim())
        {
            $Outputs |  ForEach-Object {
                           if($_)
                           {
                               $ScriptCommentHelpInfoString += ".OUTPUTS `r`n$_ `r`n`r`n"
                           }
                       }
        }

        if("$Notes".Trim())
        {
            $ScriptCommentHelpInfoString += ".NOTES `r`n$($Notes -join "`r`n") `r`n`r`n"
        }

        if("$Link".Trim())
        {
            $Link |  ForEach-Object {
                         if($_)
                         {
                              $ScriptCommentHelpInfoString += ".LINK `r`n$_ `r`n`r`n"
                         }
                     }
        }

        if("$Component".Trim())
        {
            $ScriptCommentHelpInfoString += ".COMPONENT `r`n$($Component -join "`r`n") `r`n`r`n"
        }

        if("$Role".Trim())
        {
            $ScriptCommentHelpInfoString += ".ROLE `r`n$($Role -join "`r`n") `r`n`r`n"
        }

        if("$Functionality".Trim())
        {
            $ScriptCommentHelpInfoString += ".FUNCTIONALITY `r`n$($Functionality -join "`r`n") `r`n`r`n"
        }

        $ScriptCommentHelpInfoString += "#> `r`n"

        return $ScriptCommentHelpInfoString
    }
}