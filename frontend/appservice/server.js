import { createReadStream, existsSync } from 'node:fs'
import { promises as fs } from 'node:fs'
import { createServer } from 'node:http'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const distDir = path.join(__dirname, 'dist')
const port = Number(process.env.PORT ?? 8080)

const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8',
  '.webp': 'image/webp'
}

function getContentType(filePath) {
  return contentTypes[path.extname(filePath).toLowerCase()] ?? 'application/octet-stream'
}

function safeJoin(root, requestPath) {
  const trimmedPath = requestPath.replace(/^\/+/, '')
  const fullPath = path.normalize(path.join(root, trimmedPath))
  return fullPath.startsWith(root) ? fullPath : null
}

async function resolveFile(requestPath) {
  const pathname = requestPath === '/' ? '/index.html' : requestPath
  const directPath = safeJoin(distDir, pathname)
  if (directPath && existsSync(directPath)) {
    const stats = await fs.stat(directPath)
    if (stats.isFile()) return directPath
  }

  return path.join(distDir, 'index.html')
}

createServer(async (req, res) => {
  try {
    const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`)
    const filePath = await resolveFile(url.pathname)
    const stats = await fs.stat(filePath)

    res.writeHead(200, {
      'Content-Length': stats.size,
      'Content-Type': getContentType(filePath),
      'Cache-Control': filePath.endsWith('index.html') ? 'no-cache' : 'public, max-age=31536000, immutable'
    })

    createReadStream(filePath).pipe(res)
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' })
    res.end('Not found')
  }
}).listen(port, () => {
  console.log(`Static frontend server listening on ${port}`)
})