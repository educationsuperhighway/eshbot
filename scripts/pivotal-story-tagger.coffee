# Description:
#   Listens for 'story_create_activity' from the pivotal-listener and then
#   runs a script to rename stories with a friendly ID
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
  robot.on 'story_create_activity', (project) ->
    PROJECT_ID = project.projectId
    STORY_PREFIX = project.storyPrefix
    TOKEN = process.env.PIVOTAL_TRACKER_API_TOKEN
    PIVOTAL_ENDPOINT = "https://www.pivotaltracker.com/services/v5/projects/"
    maxStoryId = 0
    taggedStoryCount = 0

    robot.logger.info "Requesting all pivotal stories..."
    robot
      .http("#{PIVOTAL_ENDPOINT}#{PROJECT_ID}/stories?limit=2000")
      .header('X-TrackerToken', TOKEN)
      .get() (err, res, body) ->
        if err
          robot.logger.error "Error making request to pivotal for project: #{PROJECT_ID}"
          robot.logger.error "Error: #{err}"
          return
        if body?
          stories = JSON.parse(body)
          stories.sort (a, b) ->
            return 0 if a['id'] == b['id']
            if a['id'] < b['id']
              return -1
            else
              return 1

          for story in stories
            robot.logger.info "#{story.name}"
            storyId = story["id"]
            storyName = story["name"]
            pattern = "^#{STORY_PREFIX}(\\d+)"
            regex = new RegExp(pattern)
            currentStoryId = null
            friendlyStoryId = storyName.match(regex)
            if friendlyStoryId
              currentStoryId = parseInt(friendlyStoryId[1])
            if currentStoryId
              maxStoryId = currentStoryId if currentStoryId > maxStoryId
              robot.logger.info "Skipping story with existing ID: #{storyName}"
              continue

            taggedStoryCount += 1
            maxStoryId += 1

            newStoryName = "#{STORY_PREFIX}#{maxStoryId} - #{storyName}"
            endpoint = "#{PIVOTAL_ENDPOINT}#{PROJECT_ID}/stories/#{storyId}"
            data = JSON.stringify({name: newStoryName})

            robot.http(endpoint)
                 .header('X-TrackerToken', TOKEN)
                 .header('Content-Type', 'application/json')
                 .put(data) (err, res, body) ->
                   if err
                     robot.logger.error "Error updating name: #{err}"
                     return
                   if res.statusCode >= 200 && res.statusCode < 300
                     robot.logger.info "Adding new ID to story: #{newStoryName}"

          robot.logger.info "Tagged #{taggedStoryCount} new stories out of #{stories.length} total."
