$root = "C:\Users\david\Downloads\Landing Piso Andia"
$port = 8800
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$port/"

$mimeMap = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript"
  ".svg"  = "image/svg+xml"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".webp" = "image/webp"
  ".avif" = "image/avif"
  ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
  try {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $res  = $ctx.Response

    $path = $req.Url.LocalPath
    if ($path -eq "/") { $path = "/index.html" }
    $file = Join-Path $root $path.TrimStart("/").Replace("/", "\")

    if (-not (Test-Path $file -PathType Leaf)) {
      $res.StatusCode = 404
      $res.OutputStream.Close()
      continue
    }

    $ext  = [System.IO.Path]::GetExtension($file).ToLower()
    $mime = if ($mimeMap[$ext]) { $mimeMap[$ext] } else { "application/octet-stream" }

    $res.ContentType      = $mime
    $res.StatusCode       = 200
    $bytes                = [System.IO.File]::ReadAllBytes($file)
    $res.ContentLength64  = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.OutputStream.Close()
  } catch {
    try { $ctx.Response.OutputStream.Close() } catch {}
  }
}
