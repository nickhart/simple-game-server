namespace :api do
  desc "Generate a new API key for the application"
  task generate_key: :environment do
    api_key = SecureRandom.hex(32)

    if Application.exists?
      application = Application.first
      application.update!(api_key: api_key)
    else
      Application.create!(
        name: "Tic Tac Toe Client",
        api_key: api_key
      )
    end

    puts "Generated API key: #{api_key}"
    puts "Please store this key securely and update the client code."
  end
end
