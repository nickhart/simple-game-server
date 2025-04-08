module JsonHelper
  def json_response
    @json_response ||= JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include JsonHelper, type: :controller
  config.include JsonHelper, type: :request
end
