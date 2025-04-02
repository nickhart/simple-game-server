namespace :test do
  desc "Run unit tests that do not require database access"
  task :units do # Remove environment dependency
    require "rake/testtask"

    Rake::TestTask.new(:run_units) do |t|
      t.libs << "test"
      t.pattern = "test/unit/**/*_test.rb"
      t.warning = false
      t.verbose = true
    end

    Rake::Task["run_units"].invoke
  end
end

# Add unit tests to the default test task
Rake::Task["test"].enhance { Rake::Task["test:units"].invoke }
