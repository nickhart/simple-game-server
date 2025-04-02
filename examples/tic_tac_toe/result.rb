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

  def success?
    @success
  end

  def failure?
    !@success
  end
end 