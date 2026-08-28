Get-ChildItem -Filter *.gif | ForEach-Object {
    $outputName = $_.Name -replace '\.gif$', '.mp4'
    ffmpeg -i $_.FullName $outputName
}