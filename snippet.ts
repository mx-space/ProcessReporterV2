function assetAuth(ctx: Context) {
  const body = ctx.req.body
  const authKey = ctx.secret.key
  if (ctx.isAuthenticated) return
  if (body.key !== authKey) {
    ctx.throws(401, 'Unauthorized')
  }
}

export default async function handler(ctx: Context) {
  const method = ctx.req.method.toLowerCase()

  switch (method) {
    case 'get': {
      return GET(ctx)
    }
    case 'post': {
      assetAuth(ctx)
      return POST(ctx)
    }

    default: {
      ctx.throws(405, 'Method Not Allowed')
    }
  }
}

interface Media {
  title: string
  artist: string
}

interface Process {
  name: string
  iconBase64?: string
  iconUrl?: string
  description?: string
}

async function GET(ctx: Context) {
  const [processInfo, mediaInfo] = await Promise.all([
    ctx.storage.cache.get<Process>('ps'),
    ctx.storage.cache.get<Media>('media'),
  ])

  return {
    processName: processInfo?.name,
    processInfo,
    mediaInfo,
  }
}
async function POST(ctx: Context) {
  const [cachedProcessInfo, cachedMediaInfo] = await Promise.all([
    ctx.storage.cache.get<Process>('ps'),
    ctx.storage.cache.get<Media>('media'),
  ])

  const ts = +new Date()

  const psInfo = ctx.req.body.process as Process
  const mediaInfo = ctx.req.body.media as Media

  if (psInfo?.name !== cachedProcessInfo?.name)
    ctx?.broadcast?.('ps-update', {
      processInfo: psInfo,
      process: psInfo.name,
      ts,
    })

  if (cachedMediaInfo?.title !== mediaInfo?.title)
    ctx?.broadcast?.('media-update', mediaInfo || null)

  if (mediaInfo) {
    await ctx.storage.cache.set('media', mediaInfo, 10)
  }
  await ctx.storage.cache.set('ps', psInfo, 300)

  return {
    ok: 1,
    mediaInfo: cachedMediaInfo,
    process: cachedProcessInfo.name,
    processInfo: cachedProcessInfo,
    timestamp: +new Date(),
  }
}
