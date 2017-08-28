require "sinatra"
require "sinatra/reloader" if settings.development?
require "artii"
require "excon"
require "erubis"

raise "TTIN_EVERY not set" unless ENV['TTIN_EVERY']

configure do
  set :erb, :escape_html => true
  set :ttin_every, (ENV['TTIN_EVERY']).to_i
end

get "/health_app_only" do
  "ok"
end

get "*" do
  healthy = true

  a = Artii::Base.new :font => 'graffiti'
  instance_number = (ENV['HOSTNAME'] || "dev-1").split("-").last

  docker_ps = begin
    `docker ps 2>&1`
  rescue Exception => ex
    healthy = false
    "docker ps FAIL: #{ex.inspect}"
  end

  kontena_agent_logs = begin
    `docker logs --tail=200 kontena-agent`
  rescue Exception => ex
    healthy = false
    "docker logs FAIL #{ex.inspect}"
  end

  kontena_agent_logs_after_ttin = nil
  kontena_agent_got_ttin = nil
  kontena_agent_ttin_tested = false
  if rand(settings.ttin_every) == 0
    kontena_agent_ttin_tested = true
    `docker kill --signal=TTIN kontena-agent`

    kontena_agent_logs_after_ttin = begin
      `docker logs --tail=20 kontena-agent`
    rescue Exception => ex
      healthy = false
      "docker logs after ttin FAIL #{ex.inspect}"
    end

    kontena_agent_got_ttin = if kontena_agent_logs_after_ttin.match("WARN -- Kontena::Agent: Thread")
      true
    else
      healthy = false
      false
    end
  end

  weave_connections, weave_targets = begin
    weave_status = Excon.get "http://localhost:6784/status"
    weave_targets_match = weave_status.body.match /Targets: (\d+)/
    weave_connections_match = weave_status.body.match /Connections: (\d+)/
    [weave_connections_match[1], weave_targets_match[1]]
  rescue Exception => ex
    healthy = false
    ["weave FAIL: #{ex.inspect}", "weave FAIL #{ex.inspect}"]
  end

  erb :index, locals: {
    instance_number_ascii: a.asciify(instance_number),
    meta_refresh_seconds: params[:refresh],
    host_date_now: Time.now,
    weave_targets: weave_targets,
    weave_connections: weave_connections,
    docker_ps: docker_ps,
    kontena_agent_logs: kontena_agent_logs,
    kontena_agent_logs_after_ttin: kontena_agent_logs_after_ttin,
    healthy: healthy,
    kontena_agent_got_ttin: kontena_agent_got_ttin,
    kontena_agent_ttin_tested: kontena_agent_ttin_tested
  }
end
