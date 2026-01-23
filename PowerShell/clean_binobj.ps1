Write-Output "Start bin/obj deletions"

$path = "C:\repos\ultraplay"
$dirs = Get-ChildItem -Path $path -Recurse -Filter "ultraplay*.csproj" -ErrorAction SilentlyContinue -Force | Select-Object -ExpandProperty DirectoryName

$dirsBin = $dirs | ForEach-Object { "$_\bin" } | Where-Object { Test-Path $_ }
$dirsObj = $dirs | ForEach-Object { "$_\obj" } | Where-Object { Test-Path $_ }

$dirsToDelete = $dirsBin + $dirsObj

$dirsToDelete | ForEach-Object {
    Write-Output "Deleting $_"
    Remove-Item -Recurse -Force -Path $_ -ErrorAction SilentlyContinue
}

Write-Output "Finish bin/obj deletions"
