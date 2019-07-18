require 'net/http'
require 'json'

JENKINS_URI = "http://192.168.91.200:8080/"
#JENKINS_URI = "http://192.168.91.200:8080/job/bld-srsb-x86-linux-default/"
JENKINS_AUTH = {
  'name' => 'admin',
  'password' => 'admin'
}

SCHEDULER.every '15s' do

  json = getFromJenkins(JENKINS_URI + 'api/json?pretty=true')

  failedJobs = Array.new
  succeededJobs = Array.new
  healthdetails = Array.new
  array = json['jobs']
  #health = json['mode']
  puts "Vigneswaran Debug texts"
  #puts health
  jobcount = array.length
  successCount = 0
  failureCount = 0
  send_event('tjobs', current: jobcount)
  #puts array
  array.each {
    |job|

    next if job['color'] == 'disabled'
    next if job['color'] == 'notbuilt'
#    next if job['color'] == 'blue'
    next if job['color'] == 'blue_anime'


    if job['color'] == 'blue'
      joburi = job['url']

      jobJson = getFromJenkins(joburi + 'api/json?pretty=true')
      #puts joburi
      puts jobJson['displayName']
      healthrec = jobJson['healthReport']
      healthrec.each{
        |healthdesc|

        puts healthdesc['description']
        healthdetails.push({ label: job['name'], value: healthdesc['description']})
        }

      next
    end
    jobStatus = '';
    if job['color'] == 'yellow' || job['color'] == 'yellow_anime'
      jobStatus = getFromJenkins(job['url'] + 'lastUnstableBuild/api/json')
    elsif job['color'] == 'aborted' || job['color'] == 'aborted_anime'
      jobStatus = getFromJenkins(job['url'] + 'lastUnsuccessfulBuild/api/json')
    else
      jobStatus = getFromJenkins(job['url'] + 'lastFailedBuild/api/json')
    end
=begin
    culprits = jobStatus['culprits']


    culpritName = getNameFromCulprits(culprits)
    if culpritName != ''
       culpritName = culpritName.partition('<').first
    end
=end


    failedJobs.push({ label: job['name'], value: false})
  }

  failed = failedJobs.size > 0
  failed = 1 > 0
  send_event('jenkinsBuildStatus', { failedJobs: failedJobs, succeededJobs: succeededJobs, failed: failed, healthdetails: healthdetails })
  #send_event('jobspassed', { items: failedJobs.values })
  successCount = healthdetails.length
  failureCount = failedJobs.length
  send_event('sjobs', current: successCount)
  send_event('fjobs', current: failureCount)
end

def getFromJenkins(path)

  uri = URI.parse(path)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  if JENKINS_AUTH['name']
    request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
  end
  response = http.request(request)

  json = JSON.parse(response.body)
  return json
end

def getNameFromCulprits(culprits)
  culprits.each {
    |culprit|
    return culprit['fullName']
  }
  return ''
end

def getDescFromHealthReport(healthReport)
  healthReport.each {
    |description|
    return healthReport['description']
  }
  return ''
end
