Describe 'Create-SQL_Server' {

    $subscription = Get-AzureRmContext
    $resourceGroupName = "ausb-sandbox-gba-rg"
    
    It 'You are in subscription: Ausbildung' {
        $subscription.Subscription.Id | Should -Be "5371caaf-f6d6-4a00-a90e-86c306cb2f9a"
    }

    Context "Keyvault" {
        $keyvaults = Get-AzureRmKeyVault -ResourceGroupName	$resourceGroupName
        $keyvaultName = 'ausb-aufg-gba-kv'
        It 'The name of the Key Vault is $keyvaultName' {
            $keyvaults.vaultName | Should -Be $keyvaultName 
        }
    }

    Context "SQL Server" {

        $sqlServers = Get-AzureRmSqlServer -ResourceGroupName $resourceGroupName 
        It 'There is only one SQL Server in the Resource Group Ausbildung' {
            $sqlServers.count | Should -Be 1
        }
        $serverName = 'ausb-testserver-gba-sqls'
        It 'The name of the SQL Server is $serverName' {
            $sqlServers.ServerName | Should -Be $serverName
         }
        
        $sqlDatabases = Get-AzureRMSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName

        It 'There are 3 databases in this SQL Server.' {
            $sqlDatabases.count | Should -Be 4 # three plus master
        }


}

}