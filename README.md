# AHB
PowerShell script that goes into each Azure subscription's resources to enable Azure Hybrid Benefit for the following services:
- Azure Virtual Machines for Windows Server, SQL Enterprise, and SQL Standard
- Azure SQL Database
- Azure SQL Managed Instance

To get this up and running, all you need to do is:
1. Open Azure Portal > Azure Cloud Shell > PowerShell 
2. Copy the PowerShell script to the Azure Cloud Shell (simply drag and drop)
3. Run the command "./ApplyAHUB.ps1"

You can then look at the CSV files generated for you reflecting the changes made.
