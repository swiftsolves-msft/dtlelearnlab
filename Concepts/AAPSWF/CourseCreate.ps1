Workflow CourseCreate
{
    $connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    #"Logging in to Azure..."
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
        New-AzureRmResourceGroupDeployment -ResourceGroupName "elearningRG540795" -TemplateUri "https://raw.githubusercontent.com/swiftsolves-msft/dtlelearnlab/master/Concepts/AAPSWF/azuredeploy1.json" -newVMName $newVMName -labVirtualNetworkName $labVirtualNetworkName -expirationDate $expirationDate
        New-AzureRmResourceGroupDeployment -ResourceGroupName "elearningRG540795" -TemplateUri "https://raw.githubusercontent.com/swiftsolves-msft/dtlelearnlab/master/Concepts/AAPSWF/azuredeploy2.json"  -newVMNamestu $newVMName -labVirtualNetworkNamestu $labVirtualNetworkName -expirationDatestu $expirationDate
    }

    #Create additional Output

    #Create a unique GUID for pair Key,Value Table
    (InlineScript { 
        $guid = New-Guid
        Set-AzureRmAutomationVariable -AutomationAccountName "elearninglab" -ResourceGroupName "rgeLearningLabOrch" -Name "StudentGUID" -Value $guid -Encrypted $False

        }
    )

    # generate a Random Password

    #$ascii=$NULL;For ($a=33;$a –le 126;$a++) {$ascii+=,[char][byte]$a }
    $alphabet=$NULL;For ($a=65;$a –le 90;$a++) {$alphabet+=,[char][byte]$a }

    Function GET-Temppassword() {
        Param(
            [int]$length=6,
            [string[]]$sourcedata
            )
 
            For ($loop=1; $loop –le $length; $loop++) {
                $TempPassword+=($sourcedata | GET-RANDOM)
            }
            return $TempPassword
        }
    
    # Store a password
    $pass = GET-Temppassword –length 6 –sourcedata $alphabet

    Set-AzureRmAutomationVariable -AutomationAccountName "elearninglab" -ResourceGroupName "rgeLearningLabOrch" -Name "StudentPassword" -Value $pass -Encrypted $False

    Checkpoint-Workflow

    $StudentVM = "NYC-Student-" + $ctxavslot

    $pip = Get-AzureRmResource | where {$_.name -eq $StudentVM -and $_.ResourceType -eq "Microsoft.Network/publicIPAddresses"}

    $pipip = (Get-AzureRmPublicIpAddress -Name $pip.name -ResourceGroupName $pip.ResourceGroupName).IpAddress

    Set-AzureRmAutomationVariable -AutomationAccountName "elearninglab" -ResourceGroupName "rgeLearningLabOrch" -Name "StudentPIP" -Value $pipip -Encrypted $False

    #generate Attachment for email, RDP file to connect to studentlab and login information.

    $attach = New-Item D:\temp\StudentLab.txt -type file

    $string1 = "full address:s:" + $StudentVM + ".eastus2.cloudapp.azure.com:3389"
    $string1

    Add-Content D:\temp\StudentLab.txt $string1

    Add-Content D:\temp\StudentLab.txt "`nprompt for credentials:i:1"

    
    $string2 = "username:s:" + $StudentVM + "\eagle"
    $string2

    Add-Content D:\temp\StudentLab.txt $string2

    Rename-Item D:\temp\StudentLab.txt D:\temp\StudentLab.rdp

    # Generate Email

    $attach = "D:\temp\StudentLab.rdp"

    $body = "Lab is created, Student jump box is up and running and avaliable. Attached is RDP connection file, username is: eagle, password is: " + $pass

    $credential = Get-AutomationPSCredential -Name 'SendGridCred'

    Send-MailMessage -Attachments $attach -From no-reply@elearning.local -Subject "Student eLearning Lab Created" -To nate.swift@live.com -Body $body -smtpServer smtp.sendgrid.net -Port 587 -Credential $credential

    #$time = Get-Date
    Write-Output "Lab Deployed ."
}
