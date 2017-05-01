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

request = require 'request-promise'
PIVOTAL_ENDPOINT = "https://www.pivotaltracker.com/services/v5/projects/"
TOKEN = process.env.PIVOTAL_TRACKER_API_TOKEN
resultsPerPage = 500

getPage = (page, projectId) =>
  request(
    url: "#{PIVOTAL_ENDPOINT}#{projectId}/stories?limit=#{resultsPerPage}&offset=#{resultsPerPage * page}",
    headers: 'X-TrackerToken': TOKEN)

sortStories = (stories) =>
  stories.sort (a, b) ->
    return 0 if a['id'] == b['id']
    if a['id'] < b['id']
      return -1
    else
      return 1

wait = (delay) =>
  return new Promise((resolve, reject) =>
    console.log('Waiting...', delay)
    setTimeout(resolve, delay)
  )

parseJson = (responses) =>
  stories = []
  for response in responses
    stories.push(JSON.parse(response)...)
  return stories

generateNewStoryNames = (project, stories) =>
  STORY_PREFIX = project.projectPrefix
  sendToPivotal = []
  taggedStoryCount = 0
  maxStoryId = 0
  for story in stories
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
      console.log "Skipping story with existing ID: #{storyName}"
      continue

    taggedStoryCount += 1
    maxStoryId += 1
    newStoryName = "#{STORY_PREFIX}#{maxStoryId} - #{storyName}"
    data = { id: storyId, name: newStoryName }
    sendToPivotal.push(data)
  return sendToPivotal

module.exports = (robot) ->
  robot.on 'story_create_activity', (project) ->
    PROJECT_ID = project.projectId
    requests = [0..6].map (n) -> getPage(n, PROJECT_ID)
    robot.logger.info "Requesting pivotal stories..."
    Promise.all(requests)
    .then(parseJson)
    .then(sortStories)
    .then (stories) =>
      sendToPivotal = generateNewStoryNames(project, stories)
      batchSize = 5

      sendNextBatch = () =>
        console.log("Sending next batch:", sendToPivotal.length)
        if sendToPivotal.length == 0
          return Promise.resolve()
        batch = sendToPivotal.splice(0, batchSize)
        return Promise.all(batch.map(updateStory))
          .then(() =>
            return wait(1000)
          ).then(sendNextBatch)

      updateStory = (story) =>
        endpoint = "#{PIVOTAL_ENDPOINT}#{PROJECT_ID}/stories/#{story.id}"
        console.log("Sending story: ", story)
        delete story.id
        return request(
          method: 'PUT',
          url: endpoint,
          body: JSON.stringify(story),
          headers:
            'X-TrackerToken': TOKEN,
            'Content-Type': 'application/json')

      return sendNextBatch()
        .catch (err) =>
          console.error(err)
          process.exit()
