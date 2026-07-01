Add-Type -AssemblyName System.Drawing
$width = 256
$height = 256
$bmp = New-Object System.Drawing.Bitmap $width, $height
$rand = New-Object System.Random

for ($x = 0; $x -lt $width; $x++) {
    for ($y = 0; $y -lt $height; $y++) {
        # Using a slight monochromatic noise (e.g. grayscale)
        $val = $rand.Next(0, 256)
        $color = [System.Drawing.Color]::FromArgb(255, $val, $val, $val)
        $bmp.SetPixel($x, $y, $color)
    }
}
$assetsPath = "c:\Project\Macrode\Macrode\Assets.xcassets\NoiseTexture.imageset"
New-Item -ItemType Directory -Force -Path $assetsPath | Out-Null
$bmp.Save("$assetsPath\NoiseTexture.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Noise texture generated."
