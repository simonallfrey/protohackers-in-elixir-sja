import Config

if config_env() == :dev do
  config :logger, :console,
    format: "$time $metadata[$level] $message\n",
    metadata: [:pid]
end

if config_env() == :test do
  config :logger, level: :warn
end
