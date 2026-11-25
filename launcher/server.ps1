# M&M Maya's Math: tiny local web server (no install needed).
# Serves the app folder at http://localhost:8765 so YouTube videos can play inside the app.
# The port stays the same every time, so Maya's saved progress is always found.
$port = 8765
$root = Split-Path -Parent $PSScriptRoot
$prefix = "http://localhost:$port/"

# If the server is already running, just open the app.
try {
  $null = Invoke-WebRequest -Uri $prefix -UseBasicParsing -TimeoutSec 2
  Start-Process $prefix
  exit
} catch {}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
if (-not $env:MM_NO_OPEN) { Start-Process $prefix }
Write-Host "M&M Maya's Math is running at $prefix"
Write-Host "Keep this window open while Maya plays. Close it when she is done."

$types = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript'; '.css'='text/css';
  '.png'='image/png'; '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.ico'='image/x-icon'; '.json'='application/json' }

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
  if ($path -eq '') { $path = 'index.html' }
  $file = [IO.Path]::GetFullPath((Join-Path $root $path))
  $res = $ctx.Response
  if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf) -and ($file -notlike '*\launcher\*')) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $res.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $res.StatusCode = 404
  }
  $res.Close()
}
