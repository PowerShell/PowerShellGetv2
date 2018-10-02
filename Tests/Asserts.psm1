
 ###########################################
#                                           #
# Assert Functions                          #
#                                           #
# Copyright (C) Microsoft Corporation, 2016 #
#                                           #
 ###########################################

#
# Assert <bool>
#
# AssertEquals <object1> <object2>
#
# AssertEqualsCaseInsensitive <object1> <object2>
#
# AssertNotEquals <object1> <object2>
#
# AssertNotEqualsCaseInsensitive <object1> <object2>
#
# AssertNotNull <object>
#
# AssertFullyQualifiedErrorIdEquals <scriptblock> <expectedFullyQualifiedErrorId>
#

#
# Converts a callstack into a simple string we can use in the error message of the form:
# bar.ps1: Line 1 <- foo.ps1: Line 1 <- prompt
#
function CallStackToString
{
  param($callstack)

  $str = @($callStack | foreach { $_.Location }) -join ' <- ';
  return $str;
}

#
# Creates a new exception for when the Assert fails
#
function NewException
{
  param
  (
    $message
  )
  
  $callstack = get-pscallstack
  $callStackStr = CallStackToString ($callstack | Select-Object -skip 1);
  $errMessage = $message;
  $exception = new-object System.Management.Automation.RuntimeException $errMessage;
  $exception.Data['PSCallStack'] = $callstack;
  
  return $exception;
}


# Usage: Assert <bool> <message>
#
function Assert
{
    $errMessage = '';
    
    if ($args.Length -ne 2)
    {
        $errMessage = "Assert takes two parameters."
    }

    if (!$args[0]) 
    {
        $errMessage = $args[1]
    }
    
    if ($errMessage)
    {
        throw (NewException $errMessage);
    }
}

# Usage: AssertFullyQualifiedErrorIdEquals <scriptblock> <expectedFullyQualifiedErrorId>
#
function AssertFullyQualifiedErrorIdEquals([scriptblock]$scriptblock, [string]$expectedFullyQualifiedErrorId)
{
    # Save old error action preference to restore it in the finally block.
    $oldErrorActionPreference = $ErrorActionPreference
                
    try
    {
        $ErrorActionPreference = "Continue"
        $myError = $null    
        $myError = . { $out = & $scriptblock } 2>&1
    }
    catch
    {
        $myError = $_
        if ($myError -eq $null)
        {
            throw (NewException "No error records were writen for the given script block: $scriptblock");
            return                   
        }

        $message = "FullyQualifiedId does not match: Excepted '" + $expectedFullyQualifiedErrorId + "' and got '" + $myError.FullyQualifiedErrorId + "'"
        AssertEquals $myError.FullyQualifiedErrorId $expectedFullyQualifiedErrorId $message
    }
    finally
    {
        $ErrorActionPreference = $oldErrorActionPreference
    }
}

# Usage: AssertEquals <object1> <object2> <message>
#
function AssertEquals
{
    Assert ($args.Length -ge 2 -and $args.Length -le 3) "AssertEquals takes either two or three parameters."
    if ($args.Length -eq 2)
    {
        Assert ($args[0] -ceq $args[1]) ("'" + $args[0] + "' does not equal '" + $args[1] + "'")
    }
    else
    {
        Assert ($args[0] -ceq $args[1]) ($args[2] + ": " + "'" + $args[0] + "' does not equal '" + $args[1] + "'")
    }
}

# Usage: AssertEqualsCaseInsensitive <object1> <object2> <message>
#
function AssertEqualsCaseInsensitive
{
    Assert ($args.Length -ge 2 -and $args.Length -le 3) "AssertEqualsCaseInsensitive takes either two or three parameters."
    if ($args.Length -eq 2)
    {
        Assert ($args[0] -ieq $args[1]) ("'" + $args[0] + "' does not equal '" + $args[1] + "'")
    }
    else
    {
        Assert ($args[0] -ieq $args[1])  ($args[2] + ": " + "'" + $args[0] + "' does not equal '" + $args[1] + "'")
    }
}

# Usage: AssertNotEquals <object1> <object2> <message>
#
function AssertNotEquals
{
    Assert ($args.Length -ge 2 -and $args.Length -le 3) "AssertNotEquals takes either two or three parameters."
    if ($args.Length -eq 2)
    {
        Assert ($args[0] -cne $args[1]) ("'" + $args[0] + "' equals '" + $args[1] + "'")
    }
    else
    {
        Assert ($args[0] -cne $args[1]) $args[2]
    }
}

# Usage: AssertNotEqualsCaseInsensitive <object1> <object2> <message>
#
function AssertNotEqualsCaseInsensitive
{
    Assert ($args.Length -ge 2 -and $args.Length -le 3) "AssertNotEqualsCaseInsensitive takes either two or three parameters."
    if ($args.Length -eq 2)
    {
        Assert ($args[0] -ine $args[1]) ("'" + $args[0] + "' equals '" + $args[1] + "'")
    }
    else
    {
        Assert ($args[0] -ine $args[1]) $args[2]
    }
}

# Usage: AssertNotNull <object> <message>
#
function AssertNotNull
{
    Assert ($args.Length -eq 2) "AssertNotNull takes two parameters."
    Assert ($args[0] -ne $()) $args[1]
}

# Usage: AssertNull <object> <message>
#
function AssertNull
{
    Assert ($args.Length -eq 2) "AssertNull takes two parameters."
    Assert ($args[0] -eq $()) $args[1]
}

# Usage: AssertNullOrEmpty <object> <message>
#
function AssertNullOrEmpty
{
    Assert ($args.Length -eq 2) "AssertNullOrEmpty takes two parameters."
    Assert ($args[0] -eq $() -or $args[0] -eq '') $args[1]
}

# This function waits for either a specified amount of time or for a script block to evaluate to true and throws an exception if the timeout period elapses.  Example:
#
#   WaitFor {get-process calc} 10000 250 "Calc.exe wasn't started within 10 seconds."
#
function WaitFor(
    [Management.Automation.ScriptBlock]$scriptBlock,
    $timeoutInMilliseconds = 10000,
    $intervalInMilliseconds = 1000,
    $exceptionMessage = (throw "Please provide a descriptive exception message to 'WaitFor' so people don't have a hard time debugging it.")
    )
{
    # Get the current time
    $startTime = [DateTime]::Now

    # Loop until the script block evaluates to true
    while (-not ($scriptBlock.Invoke()))
    {
        # Sleep for the specified interval
        sleep -mil $intervalInMilliseconds

        # If the timeout period has passed, throw an exception
        if (([DateTime]::Now - $startTime).TotalMilliseconds -gt $timeoutInMilliseconds)
        {
            throw $exceptionMessage
        }
    }
}
