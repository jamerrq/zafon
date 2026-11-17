// Prefix every user prompt with the local date/time, so the conversation keeps a
// clock even though the TUI renders none. The prompt hook rewrites the admitted
// prompt, so the stamp is persisted with the message and the model sees it too.
//
// Base idea from https://github.com/anomalyco/opencode/issues/47251. Two fixes on
// top of that snippet: @file/@skill mention offsets are shifted by the prefix,
// otherwise the attachments no longer match the text, and a prompt that already
// starts with a stamp is left alone (the hook is not an exactly-once boundary).
import { Plugin } from "@opencode/plugin"

const STAMP_RE = /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2} [+-]\d{2}:\d{2}\] /

const pad = (n: number) => String(n).padStart(2, "0")

const stamp = (d: Date) => {
  const offset = -d.getTimezoneOffset()
  const sign = offset >= 0 ? "+" : "-"
  const tz = `${sign}${pad(Math.floor(Math.abs(offset) / 60))}:${pad(Math.abs(offset) % 60)}`
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())} ${tz}`
}

type Mention = { start: number; end: number }

const shiftMentions = (attachments: ReadonlyArray<{ mention?: Mention }> | undefined, by: number) => {
  for (const item of attachments ?? []) {
    if (item.mention) {
      item.mention.start += by
      item.mention.end += by
    }
  }
}

export default Plugin.define({
  id: "user-message-timestamp",
  setup: async (ctx) => {
    await ctx.session.hook("prompt", (event) => {
      const text = event.prompt.text
      if (STAMP_RE.test(text)) return
      const prefix = `[${stamp(new Date())}] `
      shiftMentions(event.prompt.files, prefix.length)
      shiftMentions(event.prompt.skills, prefix.length)
      event.prompt.text = prefix + text
    })
  },
})
