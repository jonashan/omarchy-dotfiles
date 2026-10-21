import type { EngineInterface, Register } from 'claude-code'

// ponytail: last active session wins; one file per window if multi-session matters
const write = async ($: EngineInterface, cwd: string) => {
  const home = await $.env.get('HOME')
  await $.fs.write(`${home}/.cache/claude-cwd`, cwd).catch(() => {})
}

export const register: Register = (on) => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    await write($, await $.session.cwd())
    return r
  })
  on('turn.start', async ($, e, next) => {
    await write($, await $.session.cwd())
    return next(e)
  })
  on('classic.CwdChanged', async ($, e, next) => {
    await write($, e.new_cwd)
    return next(e)
  })
}
