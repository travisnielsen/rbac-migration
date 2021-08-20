<#
.SYNOPSIS
    This script restores Azure RBAC assignments that have been migrated from resources to resource groups back to their original state
.DESCRIPTION
    TBD 
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$rgAssignmentsFilePath,

    [Parameter(Mandatory)]
    [string]$resourceAssignmentsFilePath
)

$rgAssignments = Get-Content $rgAssignmentsFilePath | Out-String | ConvertFrom-Json
$resourceAssignments = Get-Content $resourceAssignmentsFilePath | Out-String | ConvertFrom-Json

# Remove Resource Group scoped assignments
foreach ($assignment in $rgAssignments) {
    Write-Host -ForegroundColor Green "Removing RBAC assignment: $($assignment.RoleAssignmentId)"
    Remove-AzRoleAssignment -ObjectId $assignment.ObjectId -Scope $assignment.Scope -RoleDefinitionName $assignment.RoleDefinitionName
}

# Add resource scoped assignments
foreach ($assignment in $resourceAssignments) {
    Write-Host -ForegroundColor Green "Restoring RBAC assignment: $($assignment.RoleAssignmentId)"
    New-AzRoleAssignment -ObjectId $assignment.ObjectId -Scope $assignment.Scope -RoleDefinitionName $assignment.RoleDefinitionName
}