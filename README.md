# Azure RBAC Assignment Migration

This is a sample set of scripts that can be used to migrate RBAC assignments that are linked at the resource level to Resource Groups. [Assigning RBAC permissions to Resource Groups](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/roles#overview-of-azure-role-based-access-control) is a best practice in Azure because it simplifies management and helps avoid subscription level assignment limits (currently 2000). There are three scripts in this repository:

* [get-roleassignments.ps1](scripts/get-roleassignments.ps1) : Identifies resource linked Azure RBAC assignments that share the same parent Resource Group and have the same permissions (assigned-to and role). Each of these RBAC assignments are written to a JSON file for reporting. This file can also be used as input for the migration script
* [migrate-roleassignments.ps1](scripts/migrate-roleassignments.ps1) : Takes an input file of resource-scoped Azure RBAC assignemnts and moves them to the parent Resource Group.
* [restore-roleassignments.ps1](scripts/restore-roleassignments.ps1) : Used to rollback changes made by migrate-roleassignments.ps1

## Run the scripts

Ensure you are authenticated to Azure and have a connection to the subscription you wish to update.

```powershell
Connect-AzAccount
Set-AzContext -Subscription 'your_subscription_id'
```

From your PowerShell console, switch to the `scripts` directory and run `get-roleassignments.ps1`. This will create a new subdirectory called *data* and save a .json file that contains the resource-scoped assignments.

After reviewing the contents of the output file, run `migrate-roleassignments.ps1` to execute the changes.
