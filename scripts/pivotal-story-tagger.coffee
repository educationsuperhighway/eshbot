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
    stories = []
    maxStoryId = 0
    taggedStoryCount = 0

    robot.router
      .http("#{PIVOTAL_ENDPOINT}#{PROJECT_ID}/stories")
      .header('X-TrackerToken', TOKEN)
      .get() (err, res, body) ->
        if err
          robot.logger.error "Error making request to pivotal for project: #{PROJECT_ID}"
          return

        if body
          stories.concat(JSON.parse(body))

          sortedStories = stories.sort (a, b) ->
            return 0 if a['id'] == b['id']
            return a['id'] < b['id'] ? -1 : 1

          for story in sortedStories
            pivotalId = story["id"]
            storyName = story["name"]
            pattern = "^#{STORY_PREFIX}(\\d+)"
            regex = new RegExp(pattern)
            currentStoryId = storyName.match(regex)[1]

            if currentStoryId
              storyId = parseInt(currentStoryId)
              maxStoryId = storyId if storyId > maxStoryId
              robot.logger.info "Skipping story with existing ID: #{storyName}"
              break

            taggedStoryCount += 1
            maxStoryId += 1

            newStoryName = "#{STORY_PREFIX}#{maxStoryId} - #{storyName}"
            robot.logger.info "Adding new ID to story: #{newStoryName}"

            robot.logger.info "Tagged #{taggedStoryCount} new stories out of #{sortedStories.length} total."
