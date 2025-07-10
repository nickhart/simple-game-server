class Result
  attr_reader :success, :data, :error

  def self.success(data = nil)
    new(true, data)
  end

  def self.failure(error)
    new(false, nil, error)
  end

  def initialize(success, data = nil, error = nil)
    @success = success
    @data = data
    @error = error
  end

  def self.from_http_response(response, success_class = nil, *args)
    data = extract_data(response)
    if data
      data = success_class ? success_class.new(data, *args) : data
      success(data)
    else
      failure(extract_error(response.to_json))
    end
  end

  def self.extract_data(response)
    response.is_a?(Hash) && response.key?("data") ? response["data"] : response
  end
    
  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.extract_error(response_body)
    data = JSON.parse(response_body)
    return data["error"] if data.is_a?(Hash) && data["error"]
    return handle_errors(data["errors"]) if data.is_a?(Hash) && data["errors"]

    response_body
  rescue JSON::ParserError
    response_body
  end

  def self.handle_errors(errors)
    return errors.join(", ") if errors.is_a?(Array)
    return format_hash_errors(errors) if errors.is_a?(Hash)

    errors.to_s
  end

  def self.format_hash_errors(errors)
    errors.map { |k, v| "#{k}: #{v.join(', ')}" }.join(", ")
  end
end
