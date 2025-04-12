const process = null

export default async function handler(ctx: Context) {
  const { process: processName, key, media, meta } = ctx.req.body || {}
  // handle GET
  {
    const [processInfo, mediaInfo] = await Promise.all([
      ctx.storage.cache.get('ps') as Promise<Process | undefined>,
      ctx.storage.cache.get('media') as Promise<Media | undefined>,
    ])
    if (!key) {
      return {
        processName: processInfo?.name,
        processInfo,
        mediaInfo,
      }
    }
  }

  const ts = +new Date()
  // if (Math.abs(ts - timestamp) > 1000 * 10) {
  //   ctx.throws(400, 'this request is outdate')
  //   return
  // }

  const processInfo: Process = {
    name: processName,
    ...meta,
  }

  const validKey = (await ctx.secret.key) || 'testing'
  if (key != validKey)
    ctx.throws(401, "You haven't permission to update process info")

  const originalPsInfo: Process | null = (await ctx.storage.cache.get(
    'ps',
  )) as any
  await ctx.storage.cache.set('ps', processInfo, 300)

  if (originalPsInfo?.name !== processName)
    ctx?.broadcast?.('ps-update', {
      processInfo,
      process: processInfo.name,
      ts,
    })
  if (media) {
    await ctx.storage.cache.set('media', media, 10)
  }

  const mediaInfo: Media | undefined = (await ctx.storage.cache.get(
    'media',
  )) as any
  if (mediaInfo?.title !== media?.title)
    ctx?.broadcast?.('media-update', media || null)

  return {
    ok: 1,
    mediaInfo,
    process: processInfo.name,
    processInfo,
    timestamp: +new Date(),
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
