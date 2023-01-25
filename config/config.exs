import Config

set_my_console_logger = fn ->
  config :logger, :console,
    format: {MyConsoleLogger, :format},
    # format: "$time $metadata[$level] $message\n",
    metadata: [:pid]
end

if config_env() == :dev do
  set_my_console_logger.()
end

if config_env() == :test do
  config :logger, level: :debug
  set_my_console_logger.()
end
