# Description:
#  Substitutes regexes said in the current channel
#
# Dependencies:
#  None
#
# Configuration:
#  HUBOT_REGEX_HISTORY_LINES
#
# Commands:
#   s/source/replacement/
#
# Author:
# Lefty <colin@lefty.tv>
#

class RegexHistory
  constructor: (@robot, @keep) ->
    @cache = []
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.regexhistory
        @robot.logger.info "Loading saved chat history"
        @cache = @robot.brain.data.regexhistory

  add: (message) ->
    @cache.unshift message
    while @cache.length > @keep
      @cache.pop()
    @robot.brain.data.regexhistory = @cache

  show: (lines) ->
    if (lines > @cache.length)
      lines = @cache.length
    reply = 'Showing ' + lines + ' lines of history:\n'
    reply = reply + @entryToString(message) + '\n' for message in @cache[-lines..]
    return reply

  entryToString: (event) ->
    return '[' + event.hours + ':' + event.minutes + '] ' + event.name + ': ' + event.message

  raw: ->
    return @cache

  clear: ->
    @cache = []
    @robot.brain.data.regexhistory = @cache

class RegexHistoryEntry
  constructor: (@name, @message) ->
    @time = new Date()
    @hours = @time.getHours()
    @minutes = @time.getMinutes()
    if @minutes < 10
      @minutes = '0' + @minutes

module.exports = (robot) ->

  options =
    lines_to_keep:  process.env.HUBOT_REGEX_HISTORY_LINES

  unless options.lines_to_keep
    options.lines_to_keep = 10

  history = new RegexHistory(robot, options.lines_to_keep)

  robot.hear /(.*)/i, (msg) ->
    if ! msg.message.text.match /^s\/(.*)\/(.*)\//
      history.add new RegexHistoryEntry(msg.message.user.name, msg.match[1])

  robot.hear /^s\/(.+)\/(.+)\/(g|i)?/, (msg) ->
    re_repl = msg.match[2]
    re_src = new RegExp msg.match[1], msg.match[3]

    history.raw().every (histentry) ->
      hmsg = histentry.message
      if re_src.test hmsg
        result = hmsg.replace re_src, re_repl
        msg.send "<" + histentry.name + "> " + result
        return false
