function get-nestedGroups
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$groupName
    )
    try{
        Write-Verbose "Begining search for a group $groupname using LDAP filter: (|(samaccountname=$groupname)(distinguishedName=$groupName))"
		$groupDN = (get-adgroup -LDAPFilter "(|(samaccountname=$groupname)(distinguishedName=$groupName))").distinguishedName
        $admins =(get-adgroup -LDAPFilter "(|(samaccountname=$groupname)(distinguishedName=$groupName))" -Properties member).member| Where-Object {$_ -notlike "*forest0*root*"} | %{ Get-ADObject $_ | Where-Object {$_.objectClass -eq "group"}}
        Write-Verbose "Group Found"
    }
    catch{
        try{
            Write-Verbose "Group not found on wmservice, looking in forest0.root"
            $admins = (get-adgroup -LDAPFilter "(|(samaccountname=$groupname)(distinguishedName=$groupName))" -Properties member -server forest0.root ).member | %{ Get-ADObject $_ | Where-Object {$_.objectClass -eq "group"}}
            Write-Verbose "Group found on forest0.root"
        }
        catch{return "$groupname not found - please verify if groupname or distinguishedname attribute was used in this functions"}
    }
    $groups = @()
    $groups += $admins.distinguishedName
    $groupsToReturn=@()
    $groupsToReturn += $groupdn
    #$map = @{}
    Write-Verbose "Iterating through nested groups..."
    if($admins.name.count -gt 0)
    {
        #$i = 1
        #$map.add($groupdn, $i)
        do{
            $newGroups = @()
            #$i += 1
            foreach ($gr in $groups)
            {
                Write-Verbose "Proceeding with $gr.."
                try{
                    $subgroups = ((Get-ADGroup $gr -Properties member).member | %{ Get-ADObject $_ | Where-Object {$_.objectClass -eq "group"}}).distinguishedName
                    if($subgroups -ne $null)
                    {
                        $groups+=$subgroups
                    }
                }
                catch{}
                #$map.add($gr, $i)
                $groupsToReturn += $gr
                $groups = $groups | Where-Object {$_ -ne $gr}
                
            }
            $newGroups = $groups
        }until($newGroups -eq $null)
        Write-Verbose "Run completed"
    }

    return $groupsToReturn
}