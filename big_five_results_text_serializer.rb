require 'net/http'
require 'net/https'
require 'json'

class String
  def known_pattern?
    true if self['..']
  end

  def facet?
    (self =~ /[^.]/) == 2
  end

  def to_array
    arr = self.split(".").reject! { |c| c.empty? }
    [arr[0], arr[1].to_i]
  end

  def segment?
    true if self['Domain/Facet............ Score']
  end

  def success?
    self == '201'
  end
end

class BigFiveResultsTextSerializer
  attr_reader :result

  def initialize(file)
    @contents = file
    @facets_key = 'Facets'
    @score_key = 'Overall Score'
    @result = {'NAME' => 'Rokibul Hasan'}
  end

  def serialize
    facets = {}
    @contents.each do |line|
      if line.known_pattern?
        if line.segment?
          facets = {}
          next
        end
        domain, score = line.to_array[0], line.to_array[1]
        line.facet? ? facets.merge!({domain => score}) : @result.merge!({domain => {@score_key => score, @facets_key => facets}})
      end
    end
  end
end

class BigFiveResultsPoster
  attr_reader :response_code, :token

  def initialize(result)
    @result = result
    @end_point = 'https://recruitbot.trikeapps.com/api/v1/roles/mid-senior-web-developer/big_five_profile_submissions'
  end

  def perform
    uri = URI(@end_point)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = @result.to_json
    response = https.request(request)

    @response_code = response.code
    @token = response.body if @response_code.success?
  end
end

file = File.open("BigFiveTest.txt")
object = BigFiveResultsTextSerializer.new(file)
object.serialize

poster = BigFiveResultsPoster.new(object.result)
poster.perform

puts "My result :: #{object.result}\n\n"
puts "Response code :: #{poster.response_code} and Token :: #{poster.token}\n\n"


