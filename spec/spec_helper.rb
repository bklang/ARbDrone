Dir.chdir File.join(File.dirname(__FILE__), '..')
$:.push('.')
$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << File.dirname(__FILE__)

%w{
  bundler/setup
  rspec/core
  flexmock/rspec
}.each { |f| require f }

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_framework = :flexmock
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.color_enabled = true
end

