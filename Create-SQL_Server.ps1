function Create-SQL_Server {
    <#
    .SYNOPSIS
        -Creates a SQL Server with 3 databases
        -Saves Credentials in key vault
        -Resizing of databases (optional)
        -Rmoving server or databases
    .DESCRIPTION
    ...
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string] $SubscriptionName = '',    
    
        [Parameter()]
        [string] $ResourceGroupName = '',

        [Parameter()]
        [string] $Servername = 'ausb-testserver-gba-sqls',

        [Parameter()]
        [string] $Databasename = 'ausb-testdb-gba-db',

        [Parameter()]
        [string] $Vaultname = 'ausb-aufg-gba-kv',

        [Parameter()]
        [string] $Location = 'West Europe',

        [Parameter()]
        [string] $Adminlogin = 'ServerAdmin',

        [Parameter()]
        [string] $Password = 'ChangeYourAdminPassword1'
    )
    
    Write-Host "In which subscription do you want to setup your SQL server Please select your Subscription from the list:" 
    $subscription = Get-AzureRmSubscription | Sort-Object -Property Name | `
        Select-Object -Property Name, SubscriptionId | `
        Out-GridView -Title "Select Subscription" -OutputMode Single
    $SubscriptionName = $subscription.Name

    # Exit program, if user provides an invalid input
    if ([string]::IsNullOrEmpty($SubscriptionName)) {
        Write-Host "Error: Invalid user input. Please provide a subscription from the list!" 

        return
    }

    # Switching to bu subscription
    Write-Host "Switching to subscription '$($SubscriptionName)'.." n
    Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Set-AzureRmContext

    Write-Host "In which RESOURCE GROUP do you want to setup your SQL server? Please select your RG from the list:"     
    $resourceGroup = Get-AzureRmResourceGroup | Sort-Object -Property ResourceGroupName | `
        Select-Object -Property ResourceGroupName, ResourceId, Location | `
        Out-GridView -Title "Select Resource Group" -OutputMode Single
    $ResourceGroupName = $resourceGroup.ResourceGroupName
 
    Write-Host "Using Resource Group '$($resourceGroup.ResourceGroupName)'.." 
 
    # Exit program, if user provides an invalid input
    if ([string]::IsNullOrEmpty($ResourceGroupName)) {
        Write-Host "Error: Invalid user input. Please provide a correct number from the list!" 
 
        return
    }

    Write-Host "Creating SQL Server..."
    New-AzureRmSqlServer -ResourceGroupName $ResourceGroupName -ServerName $Servername -Location $Location -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force)) 

    Write-Host "Creating Key Vault..."
    New-AzureRmKeyVault  -ResourceGroupName $ResourceGroupName -Name $Vaultname -Location $Location
    $secretvalue = ConvertTo-SecureString $Password -AsPlainText -Force
    $secret = Set-AzureKeyVaultSecret -VaultName $Vaultname -Name $Adminlogin -SecretValue $Secretvalue
        
    Write-Host "Creating Firewall..." 
    $startip = "0.0.0.0"
    $endip = "0.0.0.0" 
    $serverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
        -ServerName $Servername `
        -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip
        
    Write-Host "Creating 3 databases..."
    for ($i = 1; $i -le 3; $i++) {
        $databname = $Databasename + $i
        New-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $Servername -DatabaseName $databname -Edition "Basic" 
    }

    Write-Host "Select a database you want to change!"
    $database = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $Servername | Select-Object -Property DatabaseName, ServerName, Location, MaxSizeBytes, Edition | Out-GridView  -OutputMode Multiple

    Write-Host "Select a new edition for the selected database(s)!"
    [string[]] $edition = 'Basic', 'Standard', 'Premium', 'DataWarehouse', 'Free', 'Stretch', 'General Purpose', 'BusinessCritical'
    $selectedEdition = $edition | Out-GridView -Title "Select a new size in GB..." -OutputMode Single
    foreach ($db in $database) {
        Set-AzureRmsqldatabase -ResourceGroupName $ResourceGroupName -ServerName $Servername -DatabaseName $db.DatabaseName  -Edition $selectedEdition
    }
    Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $Servername | Select-Object -Property DatabaseName, ServerName, Location, Edition | Out-GridView -OutputMode Single
        
    Write-Host "Would you like to delete server $Servername [Y/N]?"
    $userinput = Read-Host -Prompt "[Y/N]"
    switch ($userinput.ToUpper()) {
        "Y" {
            Write-Host "Deleting SQL Server..."
            Remove-AzureRmSQLServer -ResourceGroupName $ResourceGroupName -ServerName $Servername
        }

        Default {
            Write-Host "SQL server remains unchanged!"

            Write-Host "Would you like to delete one or more databases from server $Servername [Y/N]?"
            $userinput = Read-Host -Prompt "[Y/N]"
            switch ($userinput.ToUpper()) {
                "Y" {
                    Write-Host "Select databases you want to delete!"
                    $selectedDB = Get-AzureRmSQLDatabase -ResourceGroupName $ResourceGroupName -ServerName $Servername | Out-GridView -OutputMode Multiple
                    foreach ($db in $selectedDB) {
                        Remove-AzureRmSQLDatabase -ResourceGroupName $ResourceGroupName -ServerName $Servername -DatabaseName $db.DatabaseName
                    }
                    Write-Host "Deleting selected databases..."
                }
     
                Default {
                    Write-Host "No database was deleted!"
                }
     
            }

        }

    }

}   