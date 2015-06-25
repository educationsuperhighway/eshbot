# Description:
#   Receives Aha! activity and posts to the appropriate Slack channel
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
# URLS:
#   None

module.exports = (robot) ->

  robot.catchAll (msg) ->
    # IRT-31 find Internal Reporting Tool activity
    if msg.message.user.room == 'aha_' && /feature\sIRT-\d*/.test(msg.message.text)
      attachment = msg.message.rawMessage.attachments[0]
      # if card was Shipped
      if /Shipped$/.test(attachment.fields[0].value)
        msgData = {
          channel: '#what-the-flag'
          text: ''
          attachments: msg.message.rawMessage.attachments
        }
        robot.adapter.customMessage msgData
