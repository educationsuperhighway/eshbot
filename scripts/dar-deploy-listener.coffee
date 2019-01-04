# Description:
#   Listens for DAR deploy status and parses the output
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None
#

NOTIFICATION_CHANNEL = 'rundeck-notifications'
EMAIL_SUBJECT = 'SUCCESS - [Integration and Production] Deploy'

parseLog = (data) =>
  lines = data.split('\r\n')
  refreshedList = []
  failedList = []
  refreshedPattern = /Refreshing table: (.*)/
  failedPattern = /There was an error refreshing table: (.*)/

  for line in lines
    refreshed = line.match(refreshedPattern)
    if refreshed
      refreshedList.push refreshed[1]
    failed = line.match(failedPattern)
    if failed
      failedList.push failed[1]

  successList = refreshedList.filter((e) -> failedList.indexOf(e) < 0)

  return { success: successList, failed: failedList }

handleLog = (logUrl, robot) =>
  https = require('https');
  req = https.get logUrl, (res) ->
    res.setEncoding('utf8')
    res.on('data', (d) ->
      status = parseLog d
      msgData = {
        channel: '#' + NOTIFICATION_CHANNEL
        text: 'Failed to refresh: ' + status.failed.join(',')
      }
      robot.adapter.customMessage msgData
    )
  req.on('error', (e) ->
    console.error(e)
  )

module.exports = (robot) ->

  robot.catchAll (msg) ->
    if msg.message.user.room == NOTIFICATION_CHANNEL && msg.message.user.name == 'slackbot'
      if msg.message.rawMessage.files.length > 0 && msg.message.rawMessage.files[0].name == EMAIL_SUBJECT
        handleLog msg.message.rawMessage.files[0].attachments[0].url, robot
