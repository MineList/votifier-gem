# Votifier Gem (Alpha Version)

Ruby Gem for a Votifier Server and Client for Minecraft

This version is missing a lot of features.

## Installation

Install via RubyGems:

```bash
gem install votifier
```

## Usage

```ruby
require 'votifier'

# Initialize server with public key and host:port
public_key = File.expand_path('config/sample-public.key', __dir__)
server = Votifier::MinecraftServer.new(public_key, 'some.minecraft-server.com:8192')

# Create client with keyword arguments
client = Votifier::Client.new(
  service_name:     'MineList.kr',
  minecraft_server: server
)

# Send a vote with username only
client.send_vote(username: 'Notch')
```

If you have IP address and timestamp:

```ruby
client.send_vote(
  username:   'Notch',
  ip_address: voter_ip,        # defaults to "127.0.0.1" if omitted
  timestamp:  vote_timestamp   # defaults to Time.now.to_i if omitted
)
```

You can pass a `Key` object directly to `MinecraftServer` initializer:

```ruby
raw_key = 'KEY STRING'
key     = Votifier::Key.from_key_content(raw_key, :public)
server  = Votifier::MinecraftServer.new(
  key,
  'some.minecraft-server.com',
  8192
)
client = Votifier::Client.new(
  service_name:     'MineList.kr',
  minecraft_server: server
)
client.send_vote(username: 'Notch')
```

### MinecraftServer initialization options

```ruby
Votifier::MinecraftServer.new(public_key)                            # localhost:8192
Votifier::MinecraftServer.new(public_key, 'host.example.com')         # host:8192
Votifier::MinecraftServer.new(public_key, 9999)                       # localhost:9999
Votifier::MinecraftServer.new(public_key, 'host:9999')               
Votifier::MinecraftServer.new(public_key, 'host.example.com', 9999)
```

## Server

```ruby
require 'votifier'
Votifier::Server.new(private_key_file, '0.0.0.0:8193').listen
```

## TODO

* Unit tests
* Observer pattern for vote events
* Complete YARD documentation
* Server constructor improvements
* Add `MinecraftPlayer` class (username, ip\_address)
* Use `start` instead of `listen` for server loop

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
