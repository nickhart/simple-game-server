require "net/http"
require "uri"
require "json"
require_relative "result"

class ApiClient
  def initialize(base_url, token = nil)
    @base_url = base_url
    @token = token
  end

  def with_token(token)
    self.class.new(@base_url, token)
  end

  def get(path)
    request(Net::HTTP::Get.new(uri(path)))
  end

  def post(path, body = {})
    req = Net::HTTP::Post.new(uri(path))
    req.body = body.to_json
    request(req)
  end

  def put(path, body = {})
    req = Net::HTTP::Put.new(uri(path))
    req.body = body.to_json
    puts "request: #{req.body}"
    request(req)
  end

  def patch(path, body = {})
    req = Net::HTTP::Patch.new(uri(path))
    req.body = body.to_json
    request(req)
  end

  def delete(path)
    request(Net::HTTP::Delete.new(uri(path)))
  end

  private

  def uri(path)
    URI.join(@base_url, path)
  end

  def request(req)
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{@token}" if @token

    http = Net::HTTP.new(req.uri.hostname, req.uri.port)
    http.use_ssl = req.uri.scheme == "https"

    response = http.request(req)
    body = JSON.parse(response.body) rescue { "error" => response.body }

    unless response.is_a?(Net::HTTPSuccess)
      return Result.failure(Result.extract_error(body.to_json))
    end

    Result.from_http_response(body)
  rescue StandardError => e
    Result.failure("HTTP error: #{e.message}")
  end
end