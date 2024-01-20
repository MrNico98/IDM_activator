# Change to the desktop directory
cd $env:USERPROFILE

# Specify the GitHub username
$githubUsername = "LightYagami28"

# Specify the repository name
$repositoryName = "IDM_activator"

# Specify the branch name
$branchName = "main"

# Compose the GitHub URL
$githubUrl = "https://github.com/$githubUsername/$repositoryName/archive/refs/heads/$branchName.zip"

# Download the script from GitHub
Invoke-WebRequest -Uri $githubUrl -OutFile "$repositoryName-$branchName.zip"

# Extract all from the downloaded zip file
Expand-Archive -Path "$repositoryName-$branchName.zip" -DestinationPath "." -Force

# Remove the downloaded zip file 
Remove-Item -Path "$repositoryName-$branchName.zip" -Force

# Run the script
Start-Process -FilePath ".\$repositoryName-$branchName\AIMODS_IDM_ATTIVATORE.cmd" -Wait

# Remove the extracted folder
Remove-Item -Path "$env:USERPROFILE\$repositoryName-$branchName" -Force -Confirm:$false
