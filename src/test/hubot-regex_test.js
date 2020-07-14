'use strict';

process.env.EXPRESS_PORT = 0;
process.env.PORT = 0;
process.env.HUBOT_REGEX_HISTORY_LINES = 4;

require('should');
const Helper = require('hubot-test-helper');
const scriptHelper = new Helper('../scripts/regex.js');

let room;

describe('regex', function() {
  beforeEach(() => { room = scriptHelper.createRoom(); });
  afterEach(() => { room.destroy(); });

  describe('help', () => {
    it('lists help', () => {
      room.robot.helpCommands().should.eql(['s/source/replacement/']);
    });
  });

  describe('history', function(){

    it('addOneLine', async function() {
      await room.user.say('halkeye', 'msg1');
      [{ name: 'halkeye', message: 'msg1' }].should.eql(room.robot.RegexHistory.raw());
    });

    it('addMultipleLine', async function() {
      await room.user.say('halkeye', 'msg1');
      await room.user.say('halkeye', 'msg2');
      await room.user.say('halkeye', 'msg3');
      [
        { name: 'halkeye', message: 'msg3' },
        { name: 'halkeye', message: 'msg2' },
        { name: 'halkeye', message: 'msg1' },
      ].should.eql(room.robot.RegexHistory.raw());
    });

    return it('addTruncateLines', async function() {
      room.robot.RegexHistory.clearHistory;
      await room.user.say('halkeye', 'msg1');
      await room.user.say('halkeye', 'msg2');
      await room.user.say('halkeye', 'msg3');
      await room.user.say('halkeye', 'msg4');
      await room.user.say('halkeye', 'msg5');
      [
        { name: 'halkeye', message: 'msg5' },
        { name: 'halkeye', message: 'msg4' },
        { name: 'halkeye', message: 'msg3' },
        { name: 'halkeye', message: 'msg2' },
      ].should.eql(room.robot.RegexHistory.raw());
    });
  });

  describe('Replace Tests', function(){
    it('default search replace', async function(){
      await room.user.say('halkeye', 'yo');
      await room.user.say('halkeye', 's/yo/gavin/');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> gavin']]);
    });

    it('placeholder non global', async function(){
      await room.user.say('halkeye', 'yo1 yo2 yo3');
      await room.user.say('halkeye', 's/yo(\\d+)/$1-gavin/');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> 1-gavin yo2 yo3']]);
    });

    it('placeholder global', async function(){
      await room.user.say('halkeye', 'yo1 yo2 yo3');
      await room.user.say('halkeye', 's/yo(\\d+)/$1-gavin/g');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> 1-gavin 2-gavin 3-gavin']]);
    });

    it('anything placeholder global', async function(){
      await room.user.say('halkeye', 'yo1 yo2 yo3');
      await room.user.say('halkeye', 's/(.)/1-$1/g');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> 1-y1-o1-11- 1-y1-o1-21- 1-y1-o1-3']]);
    });

    it('simple case sensitive (nonmatch)', async function(){
      await room.user.say('halkeye', 'YO');
      await room.user.say('halkeye', 's/yo/gavin/');
      room.messages.should.be.eql([
        ['halkeye', 'YO'],
        ['halkeye', 's/yo/gavin/']
      ]);
    });

    it('simple case sensitive', async function(){
      await room.user.say('halkeye', 'YO');
      await room.user.say('halkeye', 's/yo/gavin/i');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> gavin' ]]);
    });

    it('simple case sensitive global', async function(){
      await room.user.say('halkeye', 'YO yo');
      await room.user.say('halkeye', 's/yo/gavin/ig');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> gavin gavin' ]]);
    });

    it('trimmed match', async function(){
      await room.user.say('halkeye', 'msg1');
      await room.user.say('halkeye', 'msg2');
      await room.user.say('halkeye', 'msg3');
      await room.user.say('halkeye', 'msg4 msg4');
      await room.user.say('halkeye', 'msg5');
      await room.user.say('halkeye', 's/msg4/gavin/');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> gavin msg4' ]]);
    });

    it('empty replace', async function(){
      await room.user.say('halkeye', 'I wasn\'t tired');
      await room.user.say('halkeye', 's/n\'t//');
      room.messages.slice(-1).should.be.eql([['hubot', '<halkeye> I was tired' ]]);
    });
  });
});
