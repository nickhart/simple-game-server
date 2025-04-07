module CoreExtensions
  module Array
    def exclude?(value)
      !include?(value)
    end
  end
end

Array.include CoreExtensions::Array
