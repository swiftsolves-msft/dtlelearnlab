Workflow CourseCreate
{
    $connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}


    # Find the avaliable Slot to use for the course creation, avaliable slots allow unique VM names, and using an isolated VNET
    $ctxavslot = (Get-AzureRmAutomationVariable -AutomationAccountName "elearninglab" -ResourceGroupName "rgeLearningLabOrch" -Name "AvaliableSlot").value

    # If the avaliable slot is higher than is actually avalaible based on a static number you provide then reset and set slot to 1 for use. 
    if ($ctxavslot -ge 6) {
    
    $ctxavslot = 1
    
    # set slot to 2 for next run
    Set-AzureRmAutomationVariable -AutomationAccountName "elearninglab" -ResourceGroupName "rgeLearningLabOrch" -Name "AvaliableSlot" -Value 2 -Encrypted $False

    } Else {

    # Update slot to next avaliable
    $ctxavslotnew = $ctxavslot + 1

    Set-AzureRmAutomationVariable -AutomationAccountName "elearninglab" -ResourceGroupName "rgeLearningLabOrch" -Name "AvaliableSlot" -Value $ctxavslotnew -Encrypted $False
    
    }

    #Set ARM template parameters

    $labVirtualNetworkName = "VNET-" + $ctxavslot

    $newVMName = $ctxavslot

    # Grab Date\Time add an hour to pass for Lab VMs expiration
    $current = Get-Date -Date (Get-Date).AddHours(1) -Format o 
    
    $ucurrent = $current.split('.')[0] 

    $expirationDate = $ucurrent + ".000Z"

    #$expirationDate = "2017-07-03T17:00:00.000Z"
    Parallel
    {
        # Login
        #$AzureRMAccount = Add-AzureRmAccount -Credential $credentials -ServicePrincipal -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47"
        New-AzureRmResourceGroupDeployment -ResourceGroupName "elearningRG540795" -TemplateUri "https://raw.githubusercontent.com/SwiftSolves/dtlelearnlab/master/Concepts/AAPSWF/azuredeploy1.json" -newVMName $newVMName -labVirtualNetworkName $labVirtualNetworkName -expirationDate $expirationDate
        New-AzureRmResourceGroupDeployment -ResourceGroupName "elearningRG540795" -TemplateUri "https://raw.githubusercontent.com/SwiftSolves/dtlelearnlab/master/Concepts/AAPSWF/azuredeploy2.json"  -newVMNamestu $newVMName -labVirtualNetworkNamestu $labVirtualNetworkName -expirationDatestu $expirationDate
    }

    #$time = Get-Date
    Write-Output "Lab Deployed ."
}