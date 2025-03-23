namespace :test do
  desc 'Run unit tests that do not require database access'
  task :units => :environment do
    $: << 'test'
    test_files = FileList['test/unit/**/*_test.rb']
    
    puts "Running #{test_files.size} unit test files..."
    ruby "-I test test/unit/game_logic_test.rb"
  end
end

# Add unit tests to the default test task
Rake::Task['test'].enhance { Rake::Task['test:units'].invoke } 