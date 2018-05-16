function ToUpper
{
    param([string]$str)
    return $script:TextInfo.ToUpper($str)
}