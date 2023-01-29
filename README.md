# Protohackers in Elixir


## Day 3

Rather than a blocking Actor, use Erlang Term Storage, ETS table for state of
chat server. ETS tables are an efficient in-memory database included with the
Erlang virtual machine. It sits in a part of the virtual machine where
destructive updates are allowed and where garbage collection dares not approach

https://learnyousomeerlang.com/ets#the-concepts-of-ets

Example of `:ets.match` (in eralng)
``` erlang
1> ets:new(table, [named_table, bag]).
table
2> ets:insert(table, [{items, a, b, c, d}, {items, a, b, c, a}, {cat, brown, soft, loveable, selfish}, {friends, [jenn,jeff,etc]}, {items, 1, 2, 3, 1}]).
true
3> ets:match(table, {items, '$1', '$2', '_', '$1'}).
[[a,b],[1,2]]
4> ets:match(table, {items, '$114', '$212', '_', '$6'}).
[[d,a,b],[a,a,b],[1,1,2]]
5> ets:match_object(table, {items, '$1', '$2', '_', '$1'}).
[{items,a,b,c,a},{items,1,2,3,1}]
6> ets:delete(table).
true
```


https://stackoverflow.com/questions/29505161/erlang-ets-select-and-match-performance


Use telnet to interact with a line packet server:
``` sh
$ telnet localhost 5004
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
What's your username?
Simon

```
Use 'Ctrl-d' to quit.


## Day 2

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

## IEx show charlists as lists

``` elixir
[101, 102, 103, 104] == 'efgh'
#=> true

[101, 102, 103, 104] |> inspect(charlists: :as_lists)
#=> [101, 102, 103, 104]
#You can also configure IEx to always print charlists as lists:

IEx.configure(inspect: [charlists: :as_lists])
IEx.configure(inspect: [charlists: :as_charlists])
IEx.configure(inspect: [charlists: :infer])
```

https://stackoverflow.com/questions/40324929/integer-list-printed-as-string-in-elixir

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
## Anonymous functions in elixir pipelines.

TLDR; 

``` elixir
# either 

|> (&(2*&1)).()

# or

|> (fn x -> 2*x end).()

# or from Elixir 1.12

|> then(&(2*&1))

# or

|> then(fn x -> 2* x end)
```

https://stackoverflow.com/questions/24593967/how-to-pass-an-anonymous-function-to-the-pipe-in-elixir

## Control which mix tests are run 

There are 5 ways to run only specific tests with Elixir

run a single file with `mix test path_to_your_tests/your_test_file.exs`
This will run all test defined in `your_test_file.exs`

run a specific test from a specific test file by adding a colon and the line number of that test
for example `mix test path_to_your_tests/your_test_file.exs:12` will run the test at line 12 of `your_test_file.exs`

define a tag to exclude on your test methods

``` elixir
defmodule MyTests do
    @tag disabled: true
    test "some test" do
        #testtesttest
    end
end
```
on the command line execute your tests like this
`mix test --exclude disabled`

define a tag to include on your test methods

``` elixir
defmodule MyTests do
    @tag mustexec: true
    test "some test" do
        #testtesttest
    end
end
```
on the command line execute your tests like this
`mix test --only mustexec`

Generally exclude some tagged tests by adding this to your `test/test_helper.exs` file
`ExUnit.configure exclude: [disabled: true]`

Warning: Mix has an --include directive. This directive is NOT the same as the --only directive. Include is used to break the general configuration (exclusion) from the test/test_helper.exs file described under 4).

https://stackoverflow.com/questions/26150146/how-can-i-make-mix-run-only-specific-tests-from-my-suite-of-test

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
## `:gen_tcp.recv` and buffer sizes

When in packet: :raw or packet: 0 we can specify the number of bytes to read.
When we specify 0 we ask for "the whole buffer". 



Digging into the erlang source, we find this is done by querying the c buffer struct
for size and demanding this number of bytes. 

However at the high level we do not have a method of reliably determining the buffer size granted. (Apart from finding at what point recv(socket,0,timeout) maxes out which is what the test "true buffer sizes" in `echo_server_test.exs` does)

read man tcp and https://erlang.org/pipermail/erlang-questions/2011-August/060851.html

This is a graph of `div(:inet.getopts(s,[:recbuf]),2)` (gray) 
and `byte_size(:gen_tcp.recv(s,0,10_000))` vs requested buffer size as output by the test
above.

![buffersizes](./img/bufferSizeReportedVsActual2.png)

`cat /proc/sys/net/core/rmem_max` gives 212992
`cat /proc/sys/net/core/wmem_max` gives 212992

So for low values the reported value is twice the requested (and delivered) value.
Above around 64k the delivered value increases in steps, while the reported value 
tracks the requested value. Above rmem_max the delivered value maxes out at around 110% of
the reported maximum.

The real concern here is that there are three regions where the delivered value is less that the reported value. 

n.b. sndbuf and recbuf are the os buffers. buffer is the user buffer. If the user buffer is
big enough and we explictly request a number of bytes from recv there is no problem. 

The above is just a feature of recv(socket,0,timeout)

https://stackoverflow.com/questions/5081298/erlang-get-tcprecv-data-length

n.b. kernel is not obliged to return a full buffer's worth of data.


General notes on socket tcp buffering:

https://www.ciscopress.com/articles/article.asp?p=769557&seqNum=2

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
fly ips help
fly ips allocate-v4
fly ips release 37.16.27.35 -a protohackers-in-elixir-sja
fly ips list
```

## Genserver child_spec/1

Elixir 1.5 GenServer introduces overridable child_spec/1. Now instead of, in your application supervisor, calling;

``` elixir
# MyExample.Application
def start(_type, _args) do
  children = [
    worker(MyExample.MyChild, [], restart: :permanent, shutdown: 5000)
  ]
end
```
You can now let the child decide how its supposed to be implemented by overriding child_spec/1 in the child.
``` elixir
#MyExample.Application
def start(_type, _args) do
  children = [ 
    MyExample.MyChild
   ]
end

# MyExample.MyChild
def child_spec(_args) do
  %{
    id: __Module__,
    start: { __Module__, :start_link, []},
    restart: :permanent,
    shutdown: 5000,
    type: :worker
   }
end
```
You can view the defaults that child_spec/1 implements in the source code.  https://github.com/elixir-lang/elixir/blob/v1.14/lib/elixir/lib/gen_server.ex#L762

Arguments can be passed to child_spec/1 which can then be used for pattern matching and custom configurations based on the supervisor accessing it:

``` elixir
#MyExample.Application
def start(_type, _args) do
  children = [ 
    {MyExample.MyChild, "temporary"}
   ]
end

# MyExample.MyChild
def child_spec("temporary") do
  %{
    id: __Module__,
    start: { __Module__, :start_link, []},
    restart: :temporary,
    shutdown: 5000,
    type: :worker
   }
end

def child_spec(_) do
  %{
    id: __Module__,
    start: { __Module__, :start_link, []},
    restart: :permanent,
    shutdown: 5000,
    type: :worker
   }
end
```


## Rustler erlang nifs in rust very easy.

IMPORTANT: for deployment on fly.io rename hello_rust.ex to hello_rust.ex.bak
(we'll figure it out properly later.)

https://github.com/rusterlium/rustler

Add rustler to deps
``` elixir
#./mix.exs
  defp deps do
    [
      {:rustler, "~> 0.27.0"},
    ]
```

``` sh
mix rustler.new
```
Respond with `Protohackers.HelloRust` and then default.

Now, following the instructions in Rustler's README.md edit `./lib/protohackers/hello_rust.ex`
to 'declare' the elixir functions you define in `./native/protohackers_hellorust/src/lib.rs`

You can find an example `lib.rs` at https://github.com/rusterlium/NifIo/blob/master/native/io/src/lib.rs

Using precompiled rust: https://github.com/philss/rustler_precompiled
Encryption: https://til.codes/converting-encryption-code-from-elixir-to-rust-using-nif/
(full of code typos)

NIFs in zig: https://github.com/ityonemo/zigler

https://www.doctave.com/blog/2021/08/19/using-rust-with-elixir-for-code-reuse-and-performance.html

## (doom) emacs stuff

Use `projectile-replace` to replace all occurrences in a project

M-up / M-down to drag line up and down (from drag-stuff package)

## Elixir mode indentation issues

https://github.com/elixir-editors/emacs-elixir/issues/488


## Stop bluetooth audio static

``` sh
sudo apt install --reinstall pulseaudio pulseaudio-module-bluetooth
sudo apt-get install pavucontrol
pavucontrol
```
Toggle between LDAC (High Quality) and aptX HD and back, sorted me out.
(maybe stick with aptX HD...)

https://askubuntu.com/questions/1232159/ubuntu-20-04-no-sound-out-of-bluetooth-headphones

