<#  Creator @ryandengstrom - ryandengstrom.com
    Used to maintain a softpaq repository for each model specified in the HPModelsTable.
    This Script was created to script maintenance of softpaq repositories, which are used with HP SSM during OSD/IPU task sequences.
    
    REQUIREMENTS:
	HP Client Management Script Library
    		Download / Installer: https://ftp.hp.com/pub/caps-softpaq/cmit/hp-cmsl.html  
	SSM Update Script https://ryandengstrom.com/2019/04/09/apply-firmware-and-driver-updates-using-hp-system-software-manager/


    Docs: https://developers.hp.com/hp-client-management/doc/client-management-script-library
    This script was created using version 1.2 (https://ftp.hp.com/pub/caps-softpaq/cmit/release/cmsl/hp-cmsl.exe)

    THANKS:
        HP: Nathan Kofahl (@nkofahl) was very helpful in answering questions about the cmdlets and a place to report bugs.

        Loop Code: The HPModelsTable loop code (and other general code) was taken from Gary Blok's (@gwblok) post on garytown.com.
            https://garytown.com/create-hp-bios-repository-using-powershell

        Logging: The Log function was created by Ryan Ephgrave (@ephingposh)
            https://www.ephingadmin.com/powershell-cmtrace-log-function/
#>

$OS = "Win10"
$OSVER = "1803"
$SSMONLY = "ssm"
$Category1 = "bios"
$Category2 = "driver"
$RepositoryPath = "E:\HPRepository"

$LogFile = "$RepositoryPath\RepoUpdate.log"

$HPModelsTable= @(
        @{ ProdCode = '1998'; Model = "HP EliteDesk 800 G1 SFF" }
        @{ ProdCode = '829A'; Model = "HP EliteDesk 800 G3 DM 35W" }
        @{ ProdCode = '8299'; Model = "HP EliteDesk 800 G3 SFF" }
        @{ ProdCode = '837B'; Model = "HP ProBook 440 G5" }
        @{ ProdCode = '2101'; Model = "HP ProBook 640 G1" }
        @{ ProdCode = '80FD'; Model = "HP ProBook 640 G2" }
        @{ ProdCode = '818F'; Model = "HP ProBook 11 G2" }
        )

foreach ($Model in $HPModelsTable) {
    Log -Message "----------------------------------------------------------------------------" -LogFile $LogFile
    Log -Message "Checking if repository for model $($Model.Model) aka $($Model.ProdCode) exists" -LogFile $LogFile
    if (Test-Path "$($RepositoryPath)\$($Model.Model)") { Log -Message "Repository for model $($Model.Model) aka $($Model.ProdCode) already exists"-LogFile $LogFile }
    if (-not (Test-Path "$($RepositoryPath)\$($Model.Model)")) {
        Log -Message "Repository for $($Model.Model) does not exist, creating now" -LogFile $LogFile
        New-Item -ItemType Directory -Path "$($RepositoryPath)\$($Model.Model)\Repository"
        if (Test-Path "$($RepositoryPath)\$($Model.Model)\Repository") {
            Log -Message "$($Model.Model) repository folder and SSM Repository subfolder successfully created" -LogFile $LogFile
            }
        else {
            Log -Message "Failed to create SSM repository subfolder!" -LogFile $LogFile
            Exit
        }
    }
    elseif (-not (Test-Path "$($RepositoryPath)\$($Model.Model)\Repository")) {
        Log -Message "SSM Repository subfolder for $($Model.Model) does not exist, creating now" -LogFile $LogFile
        New-Item -ItemType Directory -Path "$($RepositoryPath)\$($Model.Model)\Repository"
        if (Test-Path "$($RepositoryPath)\$($Model.Model)\Repository") {
            Log -Message "$($Model.Model) SSM repository subfolder successfully created" -LogFile $LogFile
            }
        else {
            Log -Message "Failed to create repository folder for $($Model.Model)" -LogFile $LogFile
            Exit
        }
    }
    if (-not (Test-Path "$($RepositoryPath)\$($Model.Model)\Repository\.repository")) {
        Log -Message "Repository not initialized, initializing now" -LogFile $LogFile
        Set-Location -Path "$($RepositoryPath)\$($Model.Model)\Repository"
        Initialize-Repository
        if (Test-Path "$($RepositoryPath)\$($Model.Model)\Repository\.repository") {
            Log -Message "$($Model.Model) repository successfully initialized" -LogFile $LogFile
        }
        else {
            Log -Message "Failed to initialize repository for $($Model.Model)" -LogFile $LogFile
            Exit
        }
    }    
    
    Log -Message "Set location to $($Model.Model) repository" -LogFile $LogFile
    Set-Location -Path "$($RepositoryPath)\$($Model.Model)\Repository"
    
    Log -Message "Configure notification for $($Model.Model)" -LogFile $LogFile
    Set-RepositoryNotificationConfiguration smtp.mailserver.com
    Add-RepositorySyncFailureRecipient -to receipient@yourorg.com
    
    Log -Message "Remove any existing repository filter for $($Model.Model) repository" -LogFile $LogFile
    Remove-RepositoryFilter -platform $($Model.ProdCode) -yes
    
    Log -Message "Applying repository filter to $($Model.Model) repository ($os $osver, $Category1 and $Category2)" -LogFile $LogFile
    Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $OSVER -characteristic $SSMONLY -category $Category1
    Add-RepositoryFilter -platform $($Model.ProdCode) -os $OS -osver $OSVER -characteristic $SSMONLY -category $Category2
    
    Log -Message "Invoking repository sync for $($Model.Model) repository ($os $osver, $Category1 and $Category2)" -LogFile $LogFile
    Invoke-RepositorySync
    
    Log -Message "Invoking repository cleanup for $($Model.Model) repository for $Category1 and $Category2 category"-LogFile $LogFile
    Invoke-RepositoryCleanup

    Log -Message "Confirm SSM files are up to date for $($Model.Model)"-LogFile $LogFile
    $RobocopySource = "$($RepositoryPath)\SSM Base"
    $RobocopyDest = "$($RepositoryPath)\$($Model.Model)"
    $RobocopyArg = '"'+$RobocopySource+'"'+' "'+$RobocopyDest+'"'
    $RobocopyCmd = "robocopy.exe"
    Start-Process -FilePath $RobocopyCmd -ArgumentList $RobocopyArg -Wait

    Log -Message "Rebuilding the SSM UID in Administrative Mode"-LogFile $LogFile
    Start-Process -FilePath "$($RepositoryPath)\$($Model.Model)\ssm.exe" -ArgumentList "/am_bld_db" -Wait
}
Log -Message "----------------------------------------------------------------------------" -LogFile $LogFile
Log -Message "Repository Update Complete"-LogFile $LogFile
Log -Message "----------------------------------------------------------------------------" -LogFile $LogFile
Set-Location -Path $RepositoryPath