Add-Type -AssemblyName System.Drawing

$dst = "C:\TennisApp\android\app\src\main\res"
$sizes = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($folder in $sizes.Keys) {
    $size = $sizes[$folder]
    $path = Join-Path $dst $folder
    New-Item -ItemType Directory -Force -Path $path | Out-Null

    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # background
    $g.Clear([System.Drawing.Color]::FromArgb(46, 125, 50))

    # inner circle
    $m = [int]($size / 8)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(76, 175, 80))
    $g.FillEllipse($brush, $m, $m, $size - 2*$m, $size - 2*$m)

    # tennis lines
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [int]([Math]::Max(2, $size/20)))
    $cx = $size/2; $cy = $size/2; $r = $size/3
    $g.DrawArc($pen, $cx-$r, $cy-$r, 2*$r, 2*$r, 200, 140)
    $g.DrawArc($pen, $cx-$r, $cy-$r, 2*$r, 2*$r, 20, 140)

    $g.Dispose()

    $bmp.Save((Join-Path $path "ic_launcher.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Save((Join-Path $path "ic_launcher_round.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created $folder ($size x $size)"
}
Write-Host "All done!"
