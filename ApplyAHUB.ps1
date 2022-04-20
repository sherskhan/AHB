#Get all subscriptions
$azSubs = Get-AzSubscription
$dot = "....................."
$AzureVM = @()
$AzureSQLVM = @()
$AzureSQLDB = @()
$AzureSQLMI = @()

#Iterate through all subscriptions
foreach ($azSub in $azSubs)
{
    $string = "Checking subscription: "
    $string + $azSub.Name + $dot
    Set-AzContext -Subscription $azSub | Out-Null

    #Iterate through all VMs----------------------------------------------------
    foreach ($azVM in Get-AzVM)
    {
        #If AHUB is not applied for Windows Server
        if ($azVM.StorageProfile.OsDisk.OsType -ceq "Windows") 
        {   
            if ((!$azVM.LicenseType) -or ($azVM.LicenseType -ceq "None"))
            {
                $string = "[UPDATE] Updating VM License with AHUB (Windows Server): "
                $string + $azVM.Name + $dot
                $azVM.LicenseType = "Windows_Server"
                #Apply AHUB
                Update-AzVM -ResourceGroupName $azVM.ResourceGroupName -VM $azVM
                #Adding details for CSV file
                $props = @{
                    SubName = $azSub.Name
                    VMName = $azVM.Name
                    Region = $azVM.Location
                    OsType = $azVM.StorageProfile.OsDisk.OsType
                    ResourceGroupName = $azVM.ResourceGroupName
                    LicenseType = $azVM.LicenseType
                }
                $ServiceObject = New-Object -TypeName PSObject -Property $props
                $AzureVM += $ServiceObject
            }
        }
    }
    #Iterate through all SQL Server VMs----------------------------------------------------
    foreach ($azSqlVM in Get-AzSqlVM)
    {
        #Only Enterprise or Standard SKUs are supported for AHUB
        if (($azSqlVM.Sku -ceq 'Standard') -or ($azSqlVM.Sku -ceq 'Enterprise'))
        {
            if ($azSqlVM.LicenseType -ceq "PAYG")
            {
                $string = "[UPDATE] Updating VM License with AHUB (Microsoft SQL): "
                $string + $azSqlVM.Name + $dot
                Update-AzSqlVM -ResourceGroupName $azSqlVM.ResourceGroupName -Name $azSqlVM.Name -LicenseType "AHUB"
                # Adding details for CSV file
                $propsSQL = @{
                    SubName = $azSub.Name
                    VMName = $azSqlVM.Name
                    Region = $azSqlVM.Location
                    Sku = $azSqlVM.Sku
                    ResourceGroupName = $azSqlVM.ResourceGroupName
                }
                $SQLServiceObject = New-Object -TypeName PSObject -Property $propsSQL
                $AzureSQLVM += $SQLServiceObject
            }
        }
        else {
            $string = "[WARNING] Az SQL VM SKU for "
            $string2 = " does not support AHUB License"
            $string + $azSqlVM.Name + $azSqlVM.Sku + $string2
        }
    }

    #Iterate through all SQL Databases ----------------------------------------------------
    $AzureSQLServers = Get-AzResource  | Where-Object ResourceType -EQ Microsoft.SQL/servers
    foreach ($AzureSQLServer in $AzureSQLServers)
    {
        #Iterate through all SQL Server DBs that are not masters and have vCore-based purchasing model
        $AzureSQLServerDatabases = Get-AzSqlDatabase -ServerName $AzureSQLServer.Name -ResourceGroupName $AzureSQLServer.ResourceGroupName | Where-Object DatabaseName -NE "master" 
        foreach ($AzureSQLDatabase in $AzureSQLServerDatabases)
        {
            if ($AzureSQLDatabase.LicenseType -cne "BasePrice")
            {
                $string = "[UPDATE] Updating Azure SQL Database with AHUB: "
                $string + $AzureSQLDatabase.DatabaseName + $dot
            
                Set-AzSqlDatabase -ServerName $AzureSQLServer.Name -ResourceGroupName $AzureSQLServer.ResourceGroupName -DatabaseName $AzureSQLDatabase.DatabaseName -LicenseType "BasePrice"

                # Adding details for CSV file
                $propsSQL_DB = @{
                    SubName = $azSub.Name
                    ServerName = $AzureSQLServer.Name
                    ResourceGroupName = $AzureSQLServer.ResourceGroupName
                    DatabaseName = $AzureSQLDatabase.DatabaseName
                }
                $SQLDBObject = New-Object -TypeName PSObject -Property $propsSQL_DB
                $AzureSQLDB += $SQLDBObject
            }
        }
    }


    #Iterate through all SQL Managed Instances ----------------------------------------------------
    # $AzureSQLManagedInstances = Get-AzResource  | Where-Object ResourceType -EQ Microsoft.SQL/managedInstances
    # foreach ($AzureSQLMI in $AzureSQLManagedInstances)
    # {
        
    # }
}
$AzureVM | Export-Csv -Path "$($home)\AzVM-WindowsServer-Licensing-Change.csv" -NoTypeInformation -force
$AzureSQLVM | Export-Csv -Path "$($home)\AzVM-SQLVM_Std_Ent-Licensing-Change.csv" -NoTypeInformation -force
$AzureSQLVM | Export-Csv -Path "$($home)\AzSQL-DB-Licensing-Change.csv" -NoTypeInformation -force
echo "Check AzVM-Windows_Server-Licensing-Change.csv for results on Windows Server license type changes......"
echo "Check AzVM-SQL_Std_Ent-Licensing-Change.csv for results on SQL Standard/Enterprise license type changes......"
