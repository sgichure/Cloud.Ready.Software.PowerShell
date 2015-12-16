﻿#parameters
$CurrentDirectory          = 'C:\_Merge\Projects\Federauto'
$NAVClientDirectory        = 'C:\Program Files (x86)\Microsoft Dynamics NAV\80\RoleTailored Client' #Right build
$OriginalFile              = Get-ChildItem "C:\_Merge\Projects\Distri73_NAV2013.txt"
$ModifiedFile              = Get-ChildItem "$CurrentDirectory\FEDERAUTO_NAV2013.txt"
$TargetFile                = Get-ChildItem "C:\_Merge\Projects\Distri81_NAV2015.txt"
$ScriptDirectory           = 'C:\_Merge\Scripts'
$VersionListPrefixes       = 'NAVW1', 'NAVBE', 'I'
$Database                  = 'NAV2015_DISTRIPLUS_RLS_81'
$Server                    = '.\NAVDEMO'
$NAVServerName             = 'localhost'
$NAVServerInstance         = 'DynamicsNAV80'
$NAVServerManagementPort   = '7046'

#enable/disable required functions:
$SplitFiles                   = $false  #This may take a while (depending on the amount of objects)
$CreateDeltas                 = $false
$MergeVersions                = $true
$updateVersionList            = $true 
$updateDateTime               = $true
$CreateFilteredResultFolder   = $true
$DisplayObjectFilters         = $true
$OpenAraxisMergeWhenConflicts = $false
$ImportObjects                = $false
$DeleteObjects                = $false
$CompileObjects               = $false

#Constants
$MergeResultFolder         = "$CurrentDirectory\Result\"
$FilteredMergeResultFolder = "$CurrentDirectory\Result_Filtered\"
$UpgradeLogsDirectory      = "$CurrentDirectory\ProcessLogs"
$MergetoolPath     = 'C:\Program Files\Araxis\Araxis Merge\Merge.exe'

#Script Execution
Import-Module "$NAVClientDirectory\Microsoft.Dynamics.Nav.Model.Tools.psd1" -force
$NavIde = "$NAVClientDirectory\finsql.exe"

cd $CurrentDirectory
Clear-Host
Write-host "All set.  Starting Script Execution..." -ForegroundColor Green

$OriginalFolder  = $OriginalFile.DirectoryName + '\Split_' + $OriginalFile.BaseName
$ModifiedFolder  = $ModifiedFile.DirectoryName + '\Split_' + $ModifiedFile.BaseName
$TargetFolder    = $TargetFile.DirectoryName   + '\Split_' + $TargetFile.BaseName
$DeltaFolderOriginalModified  = $CurrentDirectory  + '\Delta_' + $OriginalFile.BaseName + "vs" + $ModifiedFile.BaseName
$DeltaFolderOriginalTarget    = $CurrentDirectory  + '\Delta_' + $OriginalFile.BaseName + "vs" + $TargetFile.BaseName
$DeltaFolderModifiedTarget    = $CurrentDirectory  + '\Delta_' + $ModifiedFile.BaseName + "vs" + $TargetFile.BaseName

$MergeInfoFolder = "$MergeResultFolder\MergeInfo"

If ($SplitFiles) {
    Write-Host "Splitting files" -ForegroundColor Green
    if (-not (Test-Path $OriginalFolder)) {
        Write-Host "Splitting $OriginalFile to folder $OriginalFolder.  Sit back and relax, because this can take a while..." -ForegroundColor White
        New-Item -Path $OriginalFolder -ItemType directory | Out-null
        Split-NAVApplicationObjectFile -Source $OriginalFile -Destination $OriginalFolder
    } 

    if (-not (Test-Path $ModifiedFolder)) {
        Write-Host "Splitting $ModifiedFile to folder $ModifiedFolder.  Sit back and relax, because this can take a while..." -ForegroundColor White
        New-Item -Path $ModifiedFolder -ItemType directory | Out-null
        Split-NAVApplicationObjectFile -Source $ModifiedFile -Destination $ModifiedFolder
    } 

    if (-not (Test-Path $TargetFolder)) {
        Write-Host "Splitting $TargetFile to folder $TargetFolder.  Sit back and relax, because this can take a while..." -ForegroundColor White
        New-Item -Path $TargetFolder -ItemType directory | Out-null
        Split-NAVApplicationObjectFile -Source $TargetFile -Destination $TargetFolder
    }
    
}

if($CreateDeltas){
    Write-host "Creating Delta's..." -ForegroundColor Green
    Write-Host "Creating delta between Original and Modified ..." -ForegroundColor White
    if(Test-Path $DeltaFolderOriginalModified) {remove-Item $DeltaFolderOriginalModified -Recurse -force | Out-null}
    New-Item -Path $DeltaFolderOriginalModified -ItemType directory
    Compare-NAVApplicationObject -Original $OriginalFile -Modified $ModifiedFile -Delta $DeltaFolderOriginalModified

    Write-Host "Creating delta between Original and Target ..." -ForegroundColor White
    if(Test-Path $DeltaFolderOriginalTarget) {remove-Item $DeltaFolderOriginalTarget -Recurse -force | Out-null}
    New-Item -Path $DeltaFolderOriginalTarget -ItemType directory
    Compare-NAVApplicationObject -Original $OriginalFile -Modified $TargetFile -Delta $DeltaFolderOriginalTarget
  
    #Write-Host "Creating delta between Modified and Target ..." -ForegroundColor White
    #if(Test-Path $DeltaFolderModifiedTarget) {remove-Item $DeltaFolderModifiedTarget -Recurse -force | Out-null}
    #New-Item -Path $DeltaFolderModifiedTarget -ItemType directory
    #Compare-NAVApplicationObject -Original $ModifiedFile -Modified $TargetFile -Delta $DeltaFolderModifiedTarget
}

if($MergeVersions){
    Write-Host "Merging to $MergeResultFolder ..." -ForegroundColor Green

    if(Test-Path $MergeResultFolder) {remove-Item $MergeResultFolder -Recurse -force}
    New-Item -Path $MergeResultFolder -ItemType directory | Out-null
    
    $MergeResult = Merge-NAVApplicationObject `
    if(Test-Path $MergeInfoFolder) {Remove-Item -Path $MergeInfoFolder -Recurse -Force} 
            Where-Object {$_.MergeResult –eq 'Merged' -or $_.MergeResult –eq 'Conflict'}  | 
                foreach { 
                    #try
                    #{
                        Write-Host $_.Result
                        Set-NAVApplicationObjectProperty -Target $_.Result -VersionListProperty (Merge-NAVVersionList -OriginalVersionList $_.Original.VersionList `
                                                                                                                                -ModifiedVersionList $_.Modified.VersionList `
                                                                                                                                -TargetVersionList $_.Target.VersionList `
                                                                                                                      -OriginalTime $_.Original.Time `
                                                                                                                      -ModifiedDate $_.Modified.Date `
                                                                                                                      -ModifiedTime $_.Modified.Time `
                                                                                                                      -TargetDate $_.Target.Date `
                Where-Object {$_.MergeResult –eq 'Merged' -or $_.MergeResult –eq 'Conflict'}  |
                    foreach { Set-NAVApplicationObjectProperty -Target $_.Result -VersionListProperty (Merge-NAVVersionList -OriginalVersionList $_.Original.VersionList `
                                                                                                                                    -ModifiedVersionList $_.Modified.VersionList `
                                                                                                                                    -TargetVersionList $_.Target.VersionList `
                Where-Object {$_.MergeResult –eq 'Merged' -or $_.MergeResult –eq 'Conflict'}  |
                    foreach { 
                        Set-NAVApplicationObjectProperty -Target $_.Result -DateTimeProperty (Merge-NAVDateTime -OriginalDate $_.Original.Date `
                                                                                                                      -OriginalTime $_.Original.Time `
                                                                                                                      -ModifiedDate $_.Modified.Date `
                                                                                                                      -ModifiedTime $_.Modified.Time `
                                                                                                                      -TargetDate $_.Target.Date `
        Where-Object {$_.MergeResult –ine 'Unchanged'}  |
             foreach {  
                try
                {                
                    Copy-Item  $_.Result -Destination $FilteredMergeResultFolder -ErrorAction SilentlyContinue    
                }
                catch
                {
                }
            }
    if($AllObjects){
        for ($i = 1; $i -lt 8; $i++)
        {
            switch ($i)
            {
                1 { Get-NAVObjectFilter -ObjectType "Table" -ObjectCollection $AllObjects }
                2 { Get-NAVObjectFilter -ObjectType "Page" -ObjectCollection $AllObjects }
                3 { Get-NAVObjectFilter -ObjectType "Report" -ObjectCollection $AllObjects }
                4 { Get-NAVObjectFilter -ObjectType "Codeunit" -ObjectCollection $AllObjects }
                5 { Get-NAVObjectFilter -ObjectType "Query" -ObjectCollection $AllObjects }
                6 { Get-NAVObjectFilter -ObjectType "XMLPort" -ObjectCollection $AllObjects }
                7 { Get-NAVObjectFilter -ObjectType "MenuSuite" -ObjectCollection $AllObjects }
            }
        }

    Import-NAVApplicationObjectFilesFromFolder -SourceFolder $FilteredMergeResultFolder -LogFolder "$FilteredMergeResultFolder\Log" -Server $Server -Database $Database 
        Where-Object {$_.MergeResult –eq 'Deleted'}  |
             foreach { 
                [String]$ObjectType = $_.ObjectType
                [String]$ObjectId = $_.Id

                Delete-NAVApplicationObject `
                    -DatabaseName $Database `
                    -DatabaseServer $Server `
                    -LogPath $UpgradeLogsDirectory `
                    -Filter "Type=$ObjectType;Id=$ObjectId" `
                    -SynchronizeSchemaChanges "Force" `
                    -NavServerName $NAVServerName `
                    -NavServerInstance $NAVServerInstance `
                    -NavServerManagementPort $NAVServerManagementPort `
                    -Confirm:$false                       
            }

    ParallelCompile-NAVApplicationObject -ServerName $Server -DatabaseName $Database    