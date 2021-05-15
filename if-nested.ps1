function if-nested 
{
    Param(
        [Parameter(Mandatory)]
        [string]$groupName
    )
    $data = get-adgroup -LDAPFilter "(|(samaccountname=$groupname)(distinguishedName=$groupName))" -Properties memberOf, member
    if ($data.member -ne $null -or $data.memberOf -ne $null)
    {
        return $true
    }
    else
    {
        return $false
    }
}
