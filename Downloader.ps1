# Change to the desktop directory
Set-Location $env:USERPROFILE

# Specify GitHub details
$githubUsername = "LightYagami28"
$repositoryName = "IDM_activator"
$branchName = "main"

# Compose GitHub URL
$githubUrl = "https://github.com/$githubUsername/$repositoryName/archive/refs/heads/$branchName.zip"

# Download and extract the script
Invoke-WebRequest -Uri $githubUrl -OutFile "$repositoryName-$branchName.zip"
Expand-Archive -Path "$repositoryName-$branchName.zip" -DestinationPath "." -Force
Remove-Item -Path "$repositoryName-$branchName.zip" -Force

# Run the script
Start-Process -FilePath ".\$repositoryName-$branchName\AIMODS_IDM_ATTIVATORE.cmd" -Wait

# Clean up extracted folder
Remove-Item -Path "$env:USERPROFILE\$repositoryName-$branchName" -Force -Confirm:$false
