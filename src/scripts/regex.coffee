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
    @cache.splice @keep
    @robot.brain.data.regexhistory = @cache

  raw: ->
    return @cache

  clear: ->
    @cache = []
    @robot.brain.data.regexhistory = @cache

class RegexHistoryEntry
  constructor: (@name, @message) ->

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
      else
        return true

  this.rawHistory = () ->
    history.raw()

  return this

