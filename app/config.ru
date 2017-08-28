$stdout.sync = true

require "./watchdog"
run Rack::URLMap.new({
  '/' => Sinatra::Application
})
