<#
.SYNOPSIS
    This script takes an input file of resource-scoped Azure RBAC assignemnts and moves them to the parent Resource Group.
.DESCRIPTION
    TBD 
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$resourceAssignmentsFilePath
)

$resourceAssignments = Get-Content $resourceAssignmentsFilePath | Out-String | ConvertFrom-Json
$roleAssignments = Get-AzRoleAssignment

$rgScopedAssignments = $roleAssignments | Where-Object {
    $_.Scope -Match "^((?!providers).)*$" -AND $_.Scope -notlike "/providers/Microsoft.Management/managementGroups/*" -AND $_.Scope -like "*/resourceGroups/*"
}

# List to keep track of new RBAC assignments for rollback purposes
$newRgAssignments = New-Object System.Collections.ArrayList

$rgAssignments = New-Object System.Collections.ArrayList
foreach ($item in $rgScopedAssignments) {
    $rgAssignments.Add($item)
}

foreach ($assignment in $resourceAssignments) {

    # get the parent resource group
    $parentRgPath = $assignment.Scope.ToString().Split("/providers/")[0]

    # check if the parent resource group has the assignment
    $matchingRgAssignment = $rgAssignments | Where-Object {
        $_.Scope -eq $parentRgPath -AND $_.ObjectId -eq $assignment.ObjectId -AND $_.RoleDefinitionId -eq $assignment.RoleDefinitionId
    } | Select-Object -First 1

    if (-Not $matchingRgAssignment) {
        Write-Host -ForegroundColor Green "Creating new Resource Group scoped RBAC assignment to replace: $($assignment.RoleAssignmentId)"    
        $rbacAssignment = New-AzRoleAssignment -ObjectId $assignment.ObjectId -Scope $parentRgPath -RoleDefinitionName $assignment.RoleDefinitionName
        $newRgAssignments.Add($rbacAssignment)
        $rgAssignments.Add($rbacAssignment)
    }

    Write-Host -ForegroundColor Green "Removing RBAC assignment: $($assignment.RoleAssignmentId)"
    Remove-AzRoleAssignment -ObjectId $assignment.ObjectId -Scope $assignment.Scope -RoleDefinitionName $assignment.RoleDefinitionName
}

# Save new RBAC assignments to a file to support rollback
$outputFileName = "created-" + (Get-Date -f yyyy-MM-dd_HH-mm-ss) + ".json"
$newRgAssignments | ConvertTo-Json -depth 100 | Out-File "files/${outputFileName}"