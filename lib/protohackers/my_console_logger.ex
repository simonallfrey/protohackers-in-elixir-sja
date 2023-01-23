    defmodule MyConsoleLogger do
      def format(level, message, {_date,time}=timestamp, metadata) do
        # date = Logger.Formatter.format_date(date)
        time = Logger.Formatter.format_time(time)
        pid = :erlang.pid_to_list(metadata[:pid])
        "#{time} #{pid} [#{level}] #{message}\n"
      rescue
        _ -> "could not format: #{inspect({timestamp,level, message, metadata})}"
      end
    end
