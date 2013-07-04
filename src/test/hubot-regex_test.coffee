'use strict'

hubot_regex = require('../scripts/regex.js')

###
======== A Handy Little Mocha Reference ========
https://github.com/visionmedia/should.js
https://github.com/visionmedia/mocha

Mocha hooks:
  before ()-> # before describe
  after ()-> # after describe
  beforeEach ()-> # before each it
  afterEach ()-> # after each it

Should assertions:
  should.exist('hello')
  should.fail('expected an error!')
  true.should.be.ok
  true.should.be.true
  false.should.be.false

  (()-> arguments)(1,2,3).should.be.arguments
  [1,2,3].should.eql([1,2,3])
  should.strictEqual(undefined, value)
  user.age.should.be.within(5, 50)
  username.should.match(/^\w+$/)

  user.should.be.a('object')
  [].should.be.an.instanceOf(Array)

  user.should.have.property('age', 15)

  user.age.should.be.above(5)
  user.age.should.be.below(100)
  user.pets.should.have.length(5)

  res.should.have.status(200) #res.statusCode should be 200
  res.should.be.json
  res.should.be.html
  res.should.have.header('Content-Length', '123')

  [].should.be.empty
  [1,2,3].should.include(3)
  'foo bar baz'.should.include('foo')
  { name: 'TJ', pet: tobi }.user.should.include({ pet: tobi, name: 'TJ' })
  { foo: 'bar', baz: 'raz' }.should.have.keys('foo', 'bar')

  (()-> throw new Error('failed to baz')).should.throwError(/^fail.+/)

  user.should.have.property('pets').with.lengthOf(4)
  user.should.be.a('object').and.have.property('name', 'tj')
###

class Bot
  constructor: () ->
    @brain = {
      data: {},
    }
    @brain.on = (event, cb)->
      console.log(event)
      cb()

    @logger = {
      info: (msg) -> console.log("Logger - Info", msg)
    }
    @hears = []
    @output = []

  hear: (regex, cb) ->
    @hears.push [ regex, cb ]

  send: (msg) =>
    @output.push msg

  add_message: (user, text) ->
    msg = {
      message: {
        text: text
        user: { name: user }
      },
      send: @send
    }
    msg.match = null
    @hears.forEach (hear) ->
      msg.match = msg.message.text.match(hear[0])
      if msg.match
        hear[1](msg)

describe 'history', ()->
  beforeEach () ->
    process.env.HUBOT_REGEX_HISTORY_LINES = 4
    @bot = new Bot()
    @plugin = new hubot_regex(@bot)

  it 'addOneLine', () ->
    @bot.add_message 'halkeye', 'msg1'
    [{ name: 'halkeye', message: 'msg1' }].should.eql(@plugin.rawHistory())

  it 'addMultipleLine', () ->
    @bot.add_message 'halkeye', 'msg1'
    @bot.add_message 'halkeye', 'msg2'
    @bot.add_message 'halkeye', 'msg3'
    [
      { name: 'halkeye', message: 'msg3' },
      { name: 'halkeye', message: 'msg2' },
      { name: 'halkeye', message: 'msg1' },
    ].should.eql(@plugin.rawHistory())

  it 'addTruncateLines', () ->
    @plugin.clearHistory
    @bot.add_message 'halkeye', 'msg1'
    @bot.add_message 'halkeye', 'msg2'
    @bot.add_message 'halkeye', 'msg3'
    @bot.add_message 'halkeye', 'msg4'
    @bot.add_message 'halkeye', 'msg5'
    [
      { name: 'halkeye', message: 'msg5' },
      { name: 'halkeye', message: 'msg4' },
      { name: 'halkeye', message: 'msg3' },
      { name: 'halkeye', message: 'msg2' },
    ].should.eql(@plugin.rawHistory())

describe 'Replace Tests', ()->
  beforeEach () ->
    process.env.HUBOT_REGEX_HISTORY_LINES = 4
    @bot = new Bot()
    @plugin = new hubot_regex(@bot)

  it 'default search replace', ()->
    @bot.add_message 'halkeye', 'yo'
    @bot.add_message 'halkeye', 's/yo/gavin/'
    @bot.output.should.eql ['<halkeye> gavin']

  it 'placeholder non global', ()->
    @bot.add_message 'halkeye', 'yo1 yo2 yo3'
    @bot.add_message 'halkeye', 's/yo(\\d+)/$1-gavin/'
    @bot.output.should.eql ['<halkeye> 1-gavin yo2 yo3']

  it 'placeholder global', ()->
    @bot.add_message 'halkeye', 'yo1 yo2 yo3'
    @bot.add_message 'halkeye', 's/yo(\\d+)/$1-gavin/g'
    @bot.output.should.eql ['<halkeye> 1-gavin 2-gavin 3-gavin']

  it 'anything placeholder global', ()->
    @bot.add_message 'halkeye', 'yo1 yo2 yo3'
    @bot.add_message 'halkeye', 's/(.)/1-$1/g'
    @bot.output.should.eql ['<halkeye> 1-y1-o1-11- 1-y1-o1-21- 1-y1-o1-3']

  it 'simple case sensitive (nonmatch)', ()->
    @bot.add_message 'halkeye', 'YO'
    @bot.add_message 'halkeye', 's/yo/gavin/'
    @bot.output.should.eql []

  it 'simple case sensitive', ()->
    @bot.add_message 'halkeye', 'YO'
    @bot.add_message 'halkeye', 's/yo/gavin/i'
    @bot.output.should.eql ['<halkeye> gavin' ]

  it 'simple case sensitive global', ()->
    @bot.add_message 'halkeye', 'YO yo'
    @bot.add_message 'halkeye', 's/yo/gavin/ig'
    @bot.output.should.eql ['<halkeye> gavin gavin' ]

  it 'trimmed match', ()->
    @bot.add_message 'halkeye', 'msg1'
    @bot.add_message 'halkeye', 'msg2'
    @bot.add_message 'halkeye', 'msg3'
    @bot.add_message 'halkeye', 'msg4 msg4'
    @bot.add_message 'halkeye', 'msg5'
    @bot.add_message 'halkeye', 's/msg4/gavin/'
    @bot.output.should.eql ['<halkeye> gavin msg4' ]
  
  it "empty replace", ()->
    @bot.add_message 'halkeye', "I wasn't tired"
    @bot.add_message 'halkeye', "s/n't//"
    @bot.output.should.eql ['<halkeye> I was tired' ]

