class Dashing.JenkinsBuildStatus extends Dashing.Widget

  lastPlayed: 0
  timeBetweenSounds: 300000

  onData: (data) ->
    if data.failed
      $(@node).find('div.build-failed').show()
      $(@node).find('div.build-succeeded').hide()
      $(@node).css("background-color", "#f5428d")

    else
      $(@node).find('div.build-failed').hide()
      $(@node).find('div.build-succeeded').show()
      $(@node).css("background-color", "#12b0c5")
