# Change to the desktop directory
cd "$env:USERPROFILE"

# Download the script from GitHub
Invoke-WebRequest -Uri "https://github.com/MrNico98/IDM_activator/archive/refs/heads/main.zip" -OutFile "IDM_activator-main.zip"

# Extract all from "windows_script_daboynb.zip"
Expand-Archive -Path "IDM_activator-main.zip" -DestinationPath "." -Force

# Remove the "windows_script_daboynb.zip" file 
Remove-Item -Path "IDM_activator-main.zip" -Force

# Run the script
Start-Process -FilePath ".\IDM_activator-main\AIMODS_IDM_ATTIVATORE.cmd" -wait

Remove-Item -Path "$env:USERPROFILE\IDM_activator-main" -Force -Confirm:$false
