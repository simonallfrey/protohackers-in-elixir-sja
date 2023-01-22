# Protohackers

https://www.youtube.com/watch?v=owz50_NYIZ8&t=266s

Protohackers in Elixir: day 0 - Setup and Smoke Test
Andrea Leopardi


``` sh
echo foo | nc -N localhost 7001
#    -N      shutdown(2) the network socket after EOF on the input.  Some servers require this to finish their work.
```
https://serverfault.com/questions/512722/how-to-automatically-close-netcat-connection-after-data-is-sent

## Sharing constants with module attributes.

https://stackoverflow.com/questions/37713244/access-module-attributes-outside-the-module

## Change logger level
https://hexdocs.pm/logger/1.12.3/Logger.html#module-levels

## Start elixir process with named node and connect to it with iex

``` sh
$ elixir --sname foo --cookie c1 -S mix run --no-halt

$ iex --sname bar --cookie c1 --remsh "foo@localhost"
```

## sed match

sed '/pattern1/s/pattern2/replacement/g' replaces all occurrences of 'pattern2' with 'replacement' on lines matching pattern1

## prevent fly.io keeping credit/debit card on record.

Sign up w/o card and buy \$25 credit, there is no agreement to allow further billing.

Dashboard -> Billing -> Manage Billing 

Show stripe has "No payment method"


Of course, this way you have to spend \$25...

## fly.io assign and release private ip addresses

``` sh
$ fly ips help
$ fly ips allocate-v4
$ fly ips release 37.16.27.35 -a protohackers-in-elixir-sja
```


## Stop bluetooth audio static

``` sh
$ sudo apt install --reinstall pulseaudio pulseaudio-module-bluetooth
$ sudo apt-get install pavucontrol
$ pavucontrol
```
Toggle between LDAC (High Quality) and aptX HD and back, sorted me out.
(maybe stick with aptX HD...)

https://askubuntu.com/questions/1232159/ubuntu-20-04-no-sound-out-of-bluetooth-headphones

## Change logger level of running app
https://christopherjmcclellan.wordpress.com/2018/06/02/how-to-change-elixir-log-levels-for-a-running-application/


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `protohackers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:protohackers, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/protohackers>.

