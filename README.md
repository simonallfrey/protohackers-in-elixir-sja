# Protohackers in Elixir

## Day 1
This is the second video of my "Protohackers" Elixir series. We're solving network challenges from https://protohackers.com.

I’m deploying code using a free account on https://fly.io. The source code is on GitHub: https://github.com/whatyouhide/protoh...

Some resources for the video:

• "inet:setopts/2" documentation (for the "packet" option): https://www.erlang.org/doc/man/inet.h...
• Deploying Elixir applications on Fly.io: https://fly.io/docs/elixir/getting-st...
• Documentation for the Erlang gen_tcp module: https://www.erlang.org/doc/man/gen_tc...

Other resources:

• My website: https://andrealeopardi.com
• Twitter: https://twitter.com/whatyouhide
• Mastodon: https://mas.to/@whatyouhide
• #Elixir's website: https://elixir-lang.org

Music from Uppbeat (free for Creators!):
[https://uppbeat.io/t/walz/name](https://uppbeat.io/t/walz/name)
License code: WX2ISVMMX8I1FJMDThis is the first video of a series on solving some network programming challenges in Elixir ([https://elixir-lang.org](https://elixir-lang.org/)). The challenges are from [https://protohackers.com](https://protohackers.com/).


https://www.youtube.com/watch?v=owz50_NYIZ8&t=266s

## Day 0

Protohackers in Elixir: day 0 - Setup and Smoke Test
Andrea Leopardi


``` sh
mix new protohackers --sup
mix run --no-halt
mix test
echo foo | nc -N localhost 7001
#    -N      shutdown(2) the network socket after EOF on the input.  Some servers require this to finish their work.
```
https://serverfault.com/questions/512722/how-to-automatically-close-netcat-connection-after-data-is-sent

## Sharing constants with module attributes.

https://stackoverflow.com/questions/37713244/access-module-attributes-outside-the-module

## Elixir iodata

https://hexdocs.pm/elixir/1.14.3/IO.html#module-io-data

## Change logger level

https://hexdocs.pm/logger/1.12.3/Logger.html#module-levels

## Start elixir process with named node and connect to it with iex

``` sh
$ elixir --sname foo --cookie c1 -S mix run --no-halt

$ iex --sname bar --cookie c1 --remsh "foo@localhost"
iex(foo@localhost)1> Logger.configure(level: :info)
:ok
iex(foo@localhost)1> Logger.configure(level: :debug)
:ok
```

## Elixir dbg

``` elixir
dbg(:inet.getopts(listen_socket, [:buffer]))

 [lib/protohackers/prime_server.ex:32: Protohackers.PrimeServer.init/1]
 :inet.getopts(listen_socket, [:buffer]) #=> {:ok, [buffer: 1460]}
```

## Change logger level of running app

https://christopherjmcclellan.wordpress.com/2018/06/02/how-to-change-elixir-log-levels-for-a-running-application/

## Add pid to logger (for e.g. supervised child processes)
  
``` elixir
# ./config/config.exs
if config_env() == :dev do
  config :logger, :console,
    format: "$time $metadata[$level] $message\n",
    metadata: [:pid]
end
```
Or for finegrained control.
``` elixir
# ./config/config.exs
if config_env() == :dev do
    format: {MyConsoleLogger, :format},
    metadata: [:pid]
end

# ./lib/protohackers/my_console_logger.ex
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
```
## Some shell stuff

`sed '/pattern1/s/pattern2/replacement/g'` replaces all occurrences of `pattern2` with `replacement` on lines matching `pattern1`

To have newline (\n) and other escape characters in bash strings, we can use `$'string'` syntax (ANSI-C Quoting). `$'string'` expands to string, with backslash-escaped characters replaced as specified by the ANSI C standard. 

So rather than zsh's `echo "foo\nbar"` we use `echo $'foo\nbar' | nc -N localhost 5002`

## install local fly.io tools and use them.

``` sh
curl -L https://fly.io/install.sh | sh
export FLYCTL_INSTALL="/home/s/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"
```
Also append exports to `~/.bashrc`

``` sh
fly auth login
```
Opens a browser for auth.
``` sh
fly launch
```
Initial setup of app. I chose Frankfurt.
``` sh
fly deploy
```

## prevent fly.io keeping credit/debit card on record.

Sign up w/o card and buy \$25 credit (with credit or debit card, perhaps prepaid), there is no agreement to allow further billing.

Dashboard -> Billing -> Manage Billing 

Shows stripe has "No payment method"


Of course, this way you have to spend \$25...

## fly.io assign and release private ip addresses

``` sh
$ fly ips help
$ fly ips allocate-v4
$ fly ips release 37.16.27.35 -a protohackers-in-elixir-sja
```

## (doom) emacs stuff

Use `projectile-replace` to replace all occurrences in a project

M-up / M-down to drag line up and down (from drag-stuff package)

## Elixir mode indentation issues

https://github.com/elixir-editors/emacs-elixir/issues/488


## Stop bluetooth audio static

``` sh
$ sudo apt install --reinstall pulseaudio pulseaudio-module-bluetooth
$ sudo apt-get install pavucontrol
$ pavucontrol
```
Toggle between LDAC (High Quality) and aptX HD and back, sorted me out.
(maybe stick with aptX HD...)

https://askubuntu.com/questions/1232159/ubuntu-20-04-no-sound-out-of-bluetooth-headphones

