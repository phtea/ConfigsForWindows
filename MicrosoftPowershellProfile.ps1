# Function to cut video clips using ffmpeg
function cut {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Filename,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$From,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$To
    )

    if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
        Write-Error "ffmpeg is not installed or not in your PATH."
        return
    }

    $Output = [System.IO.Path]::ChangeExtension($Filename, "") + "_cut" + [System.IO.Path]::GetExtension($Filename)
    $command = "ffmpeg -i `"$Filename`" -ss $From -to $To -map 0 -c copy `"$Output`""
    Write-Host "Running: $command"
    Invoke-Expression $command
}

function symlink {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Target,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$LinkName
    )

    # Check if the target exists
    if (-not (Test-Path -Path $Target)) {
        Write-Error "The target '$Target' does not exist."
        return
    }

    # Ensure the link name does not already exist
    if (Test-Path -Path $LinkName) {
        Write-Error "The link name '$LinkName' already exists."
        return
    }

    # Automatically determine if the target is a directory
    $isDirectory = (Get-Item -Path $Target).PSIsContainer

    # Choose the mklink flag based on the type
    $linkFlag = if ($isDirectory) { "/D" } else { "" }

    # Create the symbolic link
    $command = "cmd.exe /c mklink $linkFlag `"$LinkName`" `"$Target`""
    Write-Host "Creating symbolic link: $command"
    Invoke-Expression $command
}

# Aliases
New-Alias -Name act -Value .\venv\Scripts\activate
New-Alias -Name deact -Value deactivate

function newvenv {
    py -m venv venv
}

echo "Active profile: phtea"
