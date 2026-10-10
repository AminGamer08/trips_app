$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
# Rasterize the source compass geometry for native launcher asset catalogs.
function Write-JournalIcon([string] $taskPath, [int] $taskSize) {
    $taskBitmap = [System.Drawing.Bitmap]::new($taskSize, $taskSize)
    $taskGraphics = [System.Drawing.Graphics]::FromImage($taskBitmap)
    $taskGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $taskGraphics.ScaleTransform($taskSize / 1024.0, $taskSize / 1024.0)
    $taskGreen = [System.Drawing.ColorTranslator]::FromHtml('#547466')
    $taskCream = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#f8f9f5'))
    $taskGold = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#e6be8f'))
    $taskPen = [System.Drawing.Pen]::new($taskCream, 42)
    $taskGraphics.Clear($taskGreen)
    $taskGraphics.DrawEllipse($taskPen, 232, 232, 560, 560)
    $taskDiamond = [System.Drawing.PointF[]]@([System.Drawing.PointF]::new(690,334), [System.Drawing.PointF]::new(552,552), [System.Drawing.PointF]::new(334,690), [System.Drawing.PointF]::new(472,472))
    $taskTriangle = [System.Drawing.PointF[]]@([System.Drawing.PointF]::new(690,334), [System.Drawing.PointF]::new(552,552), [System.Drawing.PointF]::new(472,472))
    $taskGraphics.FillPolygon($taskCream, $taskDiamond)
    $taskGraphics.FillPolygon($taskGold, $taskTriangle)
    $taskCenter = [System.Drawing.SolidBrush]::new($taskGreen)
    $taskGraphics.FillEllipse($taskCenter, 495, 495, 34, 34)
    $taskBitmap.Save((Join-Path $taskRoot $taskPath), [System.Drawing.Imaging.ImageFormat]::Png)
    $taskCenter.Dispose(); $taskPen.Dispose(); $taskCream.Dispose(); $taskGold.Dispose(); $taskGraphics.Dispose(); $taskBitmap.Dispose()
}
$taskAndroid = @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}
foreach ($taskEntry in $taskAndroid.GetEnumerator()) { Write-JournalIcon "android/app/src/main/res/mipmap-$($taskEntry.Key)/ic_launcher.png" $taskEntry.Value }
$taskCatalog = Get-Content (Join-Path $taskRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
foreach ($taskEntry in $taskCatalog.images) {
    $taskSize = [double]($taskEntry.size.Split('x')[0]) * [double]($taskEntry.scale.Replace('x',''))
    Write-JournalIcon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($taskEntry.filename)" ([int]$taskSize)
}
Write-JournalIcon 'web/favicon.png' 64
foreach ($taskSize in @(192,512)) {
    Write-JournalIcon "web/icons/Icon-$taskSize.png" $taskSize
    Write-JournalIcon "web/icons/Icon-maskable-$taskSize.png" $taskSize
}
