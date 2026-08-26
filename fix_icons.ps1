$src = "C:\Users\Ashkan\Claude\Projects\اپ اندروید\android\app\src\main\res"
$dst = "C:\TennisApp\android\app\src\main\res"

foreach ($f in @("mipmap-mdpi","mipmap-hdpi","mipmap-xhdpi","mipmap-xxhdpi","mipmap-xxxhdpi")) {
    New-Item -ItemType Directory -Force -Path "$dst\$f" | Out-Null
    Copy-Item "$src\$f\*.png" "$dst\$f\" -Force
    Write-Host "Copied $f"
}
Write-Host "Done!"
