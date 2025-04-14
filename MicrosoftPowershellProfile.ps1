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

    # Validate and set output filename
    $Output = [System.IO.Path]::ChangeExtension($Filename, "") + "_cut" + [System.IO.Path]::GetExtension($Filename)

    # Construct ffmpeg command based on parameters
    $command = "ffmpeg -i `"$Filename`" "

    if ($From -ne "*") {
        $command += "-ss $From "
    }
    if ($To -ne "*") {
        $command += "-to $To "
    }

    $command += "-map 0 -c copy `"$Output`""
    
    Write-Host "Running: $command"
    Invoke-Expression $command
}

# Function to merge audio channels into one
function merge-audio {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Filename
    )

    $Output = [System.IO.Path]::ChangeExtension($Filename, "") + "_merged.mp4"
    $command = "ffmpeg -i `"$Filename`" -filter_complex `[0:a:0][0:a:1]amix=inputs=2:duration=longest[aout]` -map 0:v -map `[aout]` -c:v copy -c:a aac -b:a 192k `"$Output`""

    Write-Host "Merging audio tracks: $command"
    Invoke-Expression $command
}

# Function to compress video with quality level (0 = best, 10 = smallest)
function compress-video {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Filename,

        [ValidateRange(0,10)]
        [int]$Level
    )

    $crf = 18 + [math]::Round($Level * 1.5)  # CRF: 18 (best) to ~33 (worst)
    $Output = [System.IO.Path]::ChangeExtension($Filename, "") + "_compressed.mp4"
    $command = "ffmpeg -i `"$Filename`" -c:v libx264 -preset slow -crf $crf -c:a aac -b:a 128k `"$Output`""

    Write-Host "Compressing (level $Level, crf $crf): $command"
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
