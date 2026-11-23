# Renders the Livocal brand icons to PNG (1024x1024) with GDI+.
# Source of truth: livocal-icon-a.svg / livocal-icon-b.svg.
Add-Type -AssemblyName System.Drawing

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

function New-Gradient([float]$x, [float]$y, [float]$w, [float]$h, [string]$c1, [string]$c2) {
  $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
  return New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.ColorTranslator]::FromHtml($c1),
    [System.Drawing.ColorTranslator]::FromHtml($c2),
    45.0
  )
}

function New-Canvas {
  $bmp = New-Object System.Drawing.Bitmap 1024, 1024
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#0A0F1E'))
  return @{ Bitmap = $bmp; Graphics = $g }
}

function Add-Glow($g) {
  $path = New-RoundedPath 0 0 1024 1024 232
  $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
  $brush.CenterColor = [System.Drawing.Color]::FromArgb(88, 91, 108, 249)
  $brush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 10, 15, 30))
  $g.FillRectangle($brush, 0, 0, 1024, 1024)
  $brush.Dispose()
  return $path
}

# ---------- Icon A: monogram L ----------
$a = New-Canvas
$clipA = Add-Glow $a.Graphics
$a.Graphics.SetClip($clipA)

$inner = New-RoundedPath 120 120 784 784 168
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(24, 255, 255, 255)), 3
$a.Graphics.DrawPath($pen, $inner)
$pen.Dispose()

$stem = New-RoundedPath 392 318 124 388 62
$b1 = New-Gradient 392 318 124 388 '#6E7DFF' '#3F4ED8'
$a.Graphics.FillPath($b1, $stem)

$foot = New-RoundedPath 392 582 286 124 62
$b2 = New-Gradient 392 582 286 124 '#22E8DC' '#00A79E'
$a.Graphics.FillPath($b2, $foot)

$join = New-RoundedPath 392 582 124 124 40
$b3 = New-Gradient 392 582 124 124 '#6E7DFF' '#3F4ED8'
$a.Graphics.FillPath($b3, $join)

$b1.Dispose(); $b2.Dispose(); $b3.Dispose(); $stem.Dispose(); $foot.Dispose(); $join.Dispose(); $inner.Dispose()
$a.Graphics.ResetClip()
$a.Graphics.Dispose()
$a.Bitmap.Save("$PSScriptRoot\livocal-icon-a.png", [System.Drawing.Imaging.ImageFormat]::Png)
$a.Bitmap.Dispose()

# ---------- Icon B: two speech bubbles ----------
$c = New-Canvas
$clipB = Add-Glow $c.Graphics
$c.Graphics.SetClip($clipB)

function New-BubblePath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r,
                        [float]$tailX, [float]$tailY, [float]$tailW, [float]$tailH, [bool]$tailLeft) {
  $p = New-RoundedPath $x $y $w $h $r
  $tail = New-Object System.Drawing.Drawing2D.GraphicsPath
  if ($tailLeft) {
    $tail.AddPolygon(@(
      (New-Object System.Drawing.PointF($tailX, $tailY)),
      (New-Object System.Drawing.PointF(($tailX), ($tailY + $tailH))),
      (New-Object System.Drawing.PointF(($tailX + $tailW), $tailY))
    ))
  } else {
    $tail.AddPolygon(@(
      (New-Object System.Drawing.PointF($tailX, $tailY)),
      (New-Object System.Drawing.PointF(($tailX + $tailW), ($tailY + $tailH))),
      (New-Object System.Drawing.PointF(($tailX + $tailW), $tailY))
    ))
  }
  $p.AddPath($tail, $false)
  $tail.Dispose()
  return $p
}

$back = New-RoundedPath 330 306 440 360 96
$gb = New-Gradient 330 306 440 360 '#6E7DFF' '#3F4ED8'
$c.Graphics.FillPath($gb, $back)

$front = New-BubblePath 384 470 486 304 86 470 774 76 66 $true
$gf = New-Gradient 384 470 486 304 '#22E8DC' '#00A79E'
$c.Graphics.FillPath($gf, $front)

$barBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 10, 15, 30))
foreach ($bar in @(@(512, 556, 28, 72), @(562, 524, 28, 136), @(612, 556, 28, 72))) {
  $bp = New-RoundedPath $bar[0] $bar[1] $bar[2] $bar[3] 14
  $c.Graphics.FillPath($barBrush, $bp)
  $bp.Dispose()
}
$barBrush.Dispose()

$gb.Dispose(); $gf.Dispose(); $back.Dispose(); $front.Dispose()
$c.Graphics.ResetClip()
$c.Graphics.Dispose()
$c.Bitmap.Save("$PSScriptRoot\livocal-icon-b.png", [System.Drawing.Imaging.ImageFormat]::Png)
$c.Bitmap.Dispose()

"rendered: livocal-icon-a.png, livocal-icon-b.png"
