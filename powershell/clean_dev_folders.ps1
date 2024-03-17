param(
    [string]$Path = $pwd,
    [switch]$NoDryRun = $false
)

# this script attempts to delete all build artifacts and caches from a directory that uses the following tools:

# cmake -> only really looks for CMakeLists.txt and deletes the "out" directory, this is because Visual Studio uses the "out" directory to store build artifacts
#          and it's not easy to tell if a directory is a CMake build directory, so if your cmake build directory is not called "out" this script will not delete it
# cargo -> looks for Cargo.toml and runs "cargo clean" in the directory
# vs    -> looks for .vs directory and deletes it
# node  -> looks for node_modules directory and deletes it

if (-not $NoDryRun) {
    Write-Output "Running in dry-run mode, no files will be deleted. Use -NoDryRun to run in delete mode."
} else {
    Write-Output "Running in delete mode"
}

function ConvertBytesToHumanReadable {
    param(
        [int]$bytes
    )
    $suffixes = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($bytes -ge 1024 -and $index -lt 4) {
        $bytes = $bytes / 1024
        $index++
    }
    return "{0:N2} {1}" -f $bytes, $suffixes[$index]
}

function DeleteFiles {
    param(
        [string]$Path
    )
    if ($NoDryRun) {
        Remove-Item -Recurse -Force $Path
    } else {
        $totalSize = Get-ChildItem -Recurse -Force $Path | Measure-Object -Sum Length | Select-Object Count,Sum
        $totalCount = $totalSize.Count
        $totalSum = ConvertBytesToHumanReadable $totalSize.Sum
        Write-Output "Command would have deleted $totalCount ($totalSum) files in $Path"
    }
}

function CleanDirectoryRecursive {
    param(
        [string]$Path
    )
    $childItems = Get-ChildItem -Directory -Path $Path
    foreach ($child in $childItems) {
        $cmakelistspath = Join-Path $child -ChildPath "CMakeLists.txt"
        $cargotomlpath = Join-Path $child -ChildPath "Cargo.toml"
        $node_modulespath = Join-Path $child -ChildPath "node_modules"
        $vspath = Join-Path $child -ChildPath ".vs"
        if (Test-Path $cmakelistspath -PathType Leaf) {
            $outpath = Join-Path $child -ChildPath "out"
            if (Test-Path $outpath -PathType Container) {
                Write-Output "CMake => deleting $outpath"
                DeleteFiles -path $outpath
            }
        } elseif (Test-Path $cargotomlpath -PathType Leaf) {
            Write-Output "Deleting $cargotomlpath"
            Push-Location $child
            if ($noDryRun) {
                cargo clean
            } else {
                cargo clean --dry-run
            }
            Pop-Location
        } elseif (Test-Path $node_modulespath -PathType Container) {
            Write-Output "Deleting $node_modulespath"
            DeleteFiles -path $node_modulespath
        } elseif (Test-Path $vspath -PathType Container) {
            Write-Output "Deleting $vspath"
            DeleteFiles -path $vspath
        } else {
            CleanDirectoryRecursive -Path $child
        }
    }
}

CleanDirectoryRecursive -Path $Path