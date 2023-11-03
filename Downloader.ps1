# Change to the desktop directory
cd "$env:userprofile\Desktop"

# Download the script from GitHub
Invoke-WebRequest -Uri "https://github.com/MrNico98/IDM_activator/archive/refs/heads/main.zip" -OutFile "IDM_activator-main.zip"

# Extract all from "windows_script_daboynb.zip"
Expand-Archive -Path "IDM_activator-main.zip" -DestinationPath "." -Force

# Move the "win10_custom_iso" folder to the current directory
Move-Item -Path "IDM_activator-main\IDM_activator" -Destination "IDM_activator" -Force

# Remove the "windows_scripts-main" directory 
Remove-Item -Path "IDM_activator-main" -Recurse -Force

# Remove the "windows_script_daboynb.zip" file 
Remove-Item -Path "IDM_activator-main.zip" -Force

# Run the script
Start-Process -FilePath ".\IDM_activator\AIMODS_IDM_ATTIVATORE.cmd"
