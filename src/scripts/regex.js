// Description:
//  Substitutes regexes said in the current channel
//
// Dependencies:
//  None
//
// Configuration:
//  HUBOT_REGEX_HISTORY_LINES
//
// Commands:
//   s/source/replacement/
//
// Author:
// Lefty <colin@lefty.tv>
//

class RegexHistory {
  constructor(robot, keep) {
    this.robot = robot;
    this.keep = keep;
    this.cache = [];
    this.robot.brain.on('loaded', () => {
      if (this.robot.brain.data.regexhistory) {
        this.robot.logger.info('Loading saved chat history');
        this.cache = this.robot.brain.data.regexhistory;
      }
    });
  }

  add(message) {
    this.cache.unshift(message);
    this.cache.splice(this.keep);
    this.robot.brain.data.regexhistory = this.cache;
  }

  raw() {
    return this.cache;
  }

  clear() {
    this.cache = [];
    return this.robot.brain.data.regexhistory = this.cache;
  }
}

module.exports = function(robot) {

  const options =
    {lines_to_keep:  process.env.HUBOT_REGEX_HISTORY_LINES};

  if (!options.lines_to_keep) {
    options.lines_to_keep = 10;
  }

  const history = new RegexHistory(robot, options.lines_to_keep);
  robot.RegexHistory = history;

  const regex_regex = /^s\/(.*)\/(.*)\/([g|i]*)?$/;

  robot.hear(/(.*)/i, function(msg) {
    if (!msg.message.text.match(regex_regex)) {
      history.add({ name: msg.message.user.name, message: msg.match[1] });
    }
  });

  robot.hear(regex_regex, function(msg) {
    const re_repl = msg.match[2];
    const re_src = new RegExp(msg.match[1], msg.match[3]);

    history.raw().every(function(histentry) {
      const hmsg = histentry.message;
      if (re_src.test(hmsg)) {
        const result = hmsg.replace(re_src, re_repl);
        msg.send('<' + histentry.name + '> ' + result);
        return false;
      } else {
        return true;
      }
    });
  });
};

