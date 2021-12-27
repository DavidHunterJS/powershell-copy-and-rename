$log='./wooden.log' # LOG FILE WHERE THE TRANSCRIPT IS SAVED
$path='./base/' # PATH TO THE TARGET FILES
$copyPath=$path+'copy-to/' # PATH TO THE COPY-TO DIRECTORY
$filePrefix1='text1_' # FIRST PART OF THE PATIENT FILE
$filePrefix2='text2_' # FIRST PART OF THE PROVIDER FILE
$filePrefix3='text3_' # THE FINAL PREPEND TEXT USED ON BOTH FILES
$date=(Get-Date).ToString('yyyyMMdd') # MIDDLE OF BOTH FILES - TODAY'S DATE
$fileSuffix='_0600.txt' # LAST PART OF BOTH FILES
$file1=$filePrefix1+$date+$fileSuffix # NAME OF CURRENT PATIENT FILE
$file2=$filePrefix2+$date+$fileSuffix # NAME OF CURRENT PROVIDER FILE
$copyToCount=(Get-ChildItem $copyPath | Measure-Object).Count # GET THE NUMBER OF ITEMS IN THE COPY-TO DIRECTORY
$prepend1='ONE' # PREPEND TEXT FOR PATIENT
$prepend2='TWO' # PREPEND TEXT FOR PROVIDER
$copyAndRename1=$copyPath+$prepend1+$file1 # THIS RENAMES AND COPIES WHEN CALLED BELOW IN Copy-Item
$copyAndRename2=$copyPath+$prepend2+$file2 # THIS RENAMES AND COPIES WHEN CALLED BELOW IN Copy-Item
$file1Exists=(Test-Path -LiteralPath $path$file1 -PathType Leaf) # USED TO VERIFY PATIENT FILE EXISTS
$file2Exists=(Test-Path -LiteralPath $path$file2 -PathType Leaf) # USED TO VERIFY PROVIDER FILE EXISTS
$copyIsValid1=(Test-Path -LiteralPath $copyAndRename1 -PathType Leaf) # USED TO VERIFY THE PATIENT FILE WAS COPIED AND RENAMED OK
$copyIsValid2=(Test-Path -LiteralPath $copyAndRename2 -PathType Leaf) # USED TO VERIFY THE PROVIDER FILE WAS COPIED AND RENAMED OK
$prependIsValid1=(Test-Path -LiteralPath $path$filePrefix3$file1 -PathType Leaf) # USED TO VERIFY THAT THE SECOND FILE RENAME WENT OK
$prependIsValid2=(Test-Path -LiteralPath $path$filePrefix3$file2 -PathType Leaf) # USED TO VERIFY THAT THE SECOND FILE RENAME WENT OK
$nFiles=(Get-ChildItem $path | Where-Object { ! $_.PSIsContainer } | Measure-Object).Count # GETS THE NUMBER OF FILES IN THE TARGET DIRECTORY
$Day=(Get-Date -UFormat %u) # GETS THE NUMBER OF THE DAY OF THE WEEK
[int]$Day *= 2 # MULTIPLIES THE DAY OF THE WEEK NUMBER BY 2
[bool]$hasError=0 # A BOOLEAN VALUE TO DESIGNATE THE PRESENCE OF AN ERROR OR NOT

# CREATES A LOG FILE OF EVERYTHING THAT HAPPENS WHEN THIS SCRIPT IS RUN
Start-Transcript -Append -UseMinimalHeader -Path $log
try {
    Write-Host $path -ErrorAction Stop
}
catch {
    Write-Host "Exception Message:" $_.Exception.Message
    Write-Host "Exception Message FullName:"$Error[0].Exception.GetType().FullName
    Write-Host "The error happened at:"$_.ScriptStackTrace
    Write-Host "Sending Email with error details ..."
    Stop-Transcript
    break
}
# CHECK IF TARGET FILES EXIST
if ($file1Exists -and $file2Exists) {
    Write-Host "OK: Both Files Exist"
    # IF BOTH FILES EXIST GET THEIR DATE MODIFIED ATTRIBUTE
    $dateMod1=(Get-Item $path$file1).LastWriteTime.ToString('yyyyMMdd')
    $dateMod2=(Get-Item $path$file2).LastWriteTime.ToString('yyyyMMdd')
}else {
    $hasError=1
    Write-Host "WARNING: Some files are missing."
    if ($file1Exists) {
        $dateMod1=(Get-Item $path$file1).LastWriteTime.ToString('yyyyMMdd')
    }else {
        Write-Host "WARNING: File 1 is missing."
    }
    if ($file2Exists) {
        $dateMod2=(Get-Item $path$file2).LastWriteTime.ToString('yyyyMMdd')
    }else {
        Write-Host "WARNING: File 2 is missing."
    }
    break
}
# CHECK IF THE CURRENT DAY OF THE WEEK MATCHES THE NUMBER OF EXPECTED FILES IN THE DIRECTORY
if ($nFiles -eq $nDay) {
    Write-Host "OK: The number of files match the number of the day of the week."
}else {
    $hasError=1
    Write-Host "WARNING: There are"$nFiles" file(s) in the target directory when there should be" $Day "files."
    break
}
# CHECK IF TARGET FILES HAVE TODAY'S DATE
if ($dateMod1 -eq $date -and $dateMod2 -eq $date) {
    Write-Host "OK: The files have today's date."
}else {
    if ($dateMod1 -ne $date) {
        $hasError=1
        Write-Host "WARNING: File One doesn't have today's date."
    }
    if ($dateMod2 -ne $date) {
        $hasError=1
        Write-Host "WARNING: File Two doesn't have today's date."
    }
    break
}
# CHECK IF COPY-TO FOLDER IS EMPTY AS IT SHOULD BE
if ($copyToCount -eq 0) {
    Write-Host "OK: The Copy-To folder is empty as it should be."
}else {
    $hasError=1
    Write-Host "WARNING: The Copy-To folder is not empty."
}

if (!$hasError) {
    Write-Host "OK: The files are getting copied."
    # Copy-Item -Path $path$file1 -Destination $copyAndRename1
    # Copy-Item -Path $path$file2 -Destination $copyAndRename2
}else {
    # IF THERE WERE ERRORS LIST BOTH DIRECTORIES STOP THE TRANSCRIPT AND SEND AN EMAIL
    Write-Host "WARNING: The copy process was aborted due to errors."
    Get-ChildItem -Path $copyPath
    Get-ChildItem -Path $path
    # STOP TRANSCRIPT 
    # SEND FAILURE EMAIL
}

# COPY AND RENAME THE FILES IF THERE WERE NO ERRORS
# CHECK THAT THE FILES WERE RENAMED AND COPIED CORRECTLY
if ($copyIsValid1 -and $copyIsValid2) {
    Write-Host "OK: The files were renamed and copied successfully."
    Get-ChildItem -Path $path
    Get-ChildItem -Path $copyPath
    # SEND SUCCESS EMAIL
}else {
    $hasError=1
    Write-Host "WARNING: Something failed during the copy process."
    Get-ChildItem -Path $copyPath
    # STOP TRANSCRIPT
    # SEND FAILURE EMAIL
}
# DO THE FINAL PREPEND ON THE FILES IN THE BASE DIRECTORY
if (!$hasError) {
    Write-Host "OK: The files are going to be renamed now."
    Rename-Item -Path $path$file1 -NewName $filePrefix3$file1
    Rename-Item -Path $path$file2 -NewName $filePrefix3$file1
}else {
    Write-Host "WARNING: There were errors copying the final file prepends."
    # STOP TRANSCRIPT
    # SEND FAILURE EMAIL
}
# VERIFY THAT THE FINAL PREPENDS WENT AS PLANNED
if ($prependIsValid1 -and $prependIsValid2) {
    Write-Host "OK: The prepend files are valid CUSTOMIZE MESSAGE."
    Get-ChildItem -Path $path
}else {
    $hasError=1
    Write-Host "WARNING: The prepend with CUSTOMIZE MESSAGE failed."
    # SEND FAILURE EMAIL
}
Stop-Transcript