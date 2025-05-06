require "yaml"

module ConfigLoader
  def self.load!(required_keys = [], config_dir: Dir.pwd)
    path = File.join(config_dir, "config.yml")
    config = YAML.load_file(path)

    if required_keys.any?
      missing = required_keys.select { |key| config[key].nil? || config[key].to_s.strip.empty? }
      unless missing.empty?
        raise "Missing required config keys in config.yml: #{missing.join(', ')}"
      end
    end

    config
  end
end
