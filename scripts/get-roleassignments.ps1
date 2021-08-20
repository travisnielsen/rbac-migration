<#
.SYNOPSIS
    This script identifies resource linked Azure RBAC assignments that share the same parent Resource Group and have the same permissions (assigned-to and role).
    Each of these RBAC assignments are written to a JSON file for reporting. This file can also be used as input for the migration script (migrate-roleassignments.ps1)
.DESCRIPTION
    TBD 
#>

$roleAssignments = Get-AzRoleAssignment

# Make a list of all resource scoped assignments (contains 'providers' in the scope)
$resScopedAssignments = $roleAssignments | Where-Object { $_.Scope -Match "/providers/" -AND $_.Scope -notlike "/providers/Microsoft.Management/managementGroups/*" }

# List of redundant RBAC assignments scoped at the resource level
$redundantAssignments = New-Object System.Collections.ArrayList

# find redundant RBAC assignments and add them to the list
foreach ($assignment in $resScopedAssignments) {
    $parentRgPath = $assignment.Scope.ToString().Split("/providers/")[0]
    $matchValue = $parentRgPath + "*"

    $match = $resScopedAssignments | Where-Object {
        $_.Scope -like $matchValue -AND $_.RoleDefinitionId -EQ $assignment.RoleDefinitionId -AND $_.ObjectId -EQ $assignment.ObjectId -AND $_.RoleAssignmentId -ne $assignment.RoleAssignmentId
    } | Select-Object -First 1

    if ($match) {
        $redundantAssignments.Add($assignment)
    }
}

$outputFileName = "identified-" + (Get-Date -f yyyy-MM-dd_HH-mm-ss) + ".json"

$folderName = "data"
If(!(test-path $folderName))
{
      New-Item -ItemType Directory -Force -Path $folderName
}

$redundantAssignments | ConvertTo-Json -depth 100 | Out-File -Force "${folderName}/${outputFileName}"
Write-Host -ForegroundColor Green "$($redundantAssignments.Count) resource-scoped RBAC assignments are reduntant and should be moved to the parent resource group"