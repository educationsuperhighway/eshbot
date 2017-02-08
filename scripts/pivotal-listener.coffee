# Description:
#   Receives Pivotal story activity and emits to pivotal-story-tagger
#   when a new story is created
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
#   '/hubot/pivotal-listener'

module.exports = (robot) ->

  robot.router.post "/hubot/pivotal-listener", (req, res) ->
    try
      reqBody = JSON.parse req.body
    catch error
      robot.logger.error "Error parsing json: #{error}"
      reqBody = nil
      return
    if reqBody
      res.send 'OK'
      activityType = reqBody["kind"]
      projectName = reqBody["project"]["name"]
      projectStoryPrefixMap =
        "District Portal": "DTP-",
        "CCK12": "CCK12-",
        "IRT": "IRT-",
        "Salesforce": "SF-"

      project =
        projectId: reqBody["project"]["id"]
        storyPrefix: projectStoryPrefixMap[projectName]

      if activityType == 'story_create_activity' && project.projectId
        robot.emit 'story_create_activity', project
