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
      reqBody = req.body
    catch error
      robot.logger.error "Error parsing json: #{error}"
      reqBody = null
      return
    if reqBody
      res.send 'OK'
      activityType = reqBody["kind"]
      projectName = reqBody["project"]["name"]
      projectPrefixMap =
        "District Portal": "DTP-",
        "CCK12": "CCK12-",
        "IRT": "IRT-",
        "Salesforce": "SF-",
        "Data Integration": "DI-",
        "CCK12 Design": "CCK12Design-",
        "Data Warehouse": "DW-"
        "Ecto/Material Girl": "ECTO-",
        "Fiber Toolkit": "FTK-",
        "SOTS Progress Tracking": "SOTS-",
        "TechDebt": "TD-",
        "SAT": "SAT-",
        "Salesforce": "SF-",
        "CCK12 Design": "CCK12D-",
        "Data Architecture Revamp": "DAR-"

      project =
        projectId: reqBody["project"]["id"]
        projectPrefix: projectPrefixMap[projectName]
      if activityType == 'story_create_activity' && project.projectId
        robot.logger.info "Emitting create story for project: #{projectName}"
        robot.emit 'story_create_activity', project
