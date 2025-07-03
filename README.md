# Votifier Gem (Alpha Version)

Ruby Gem for a Votifier Server and Client for Minecraft

This version is missing a lot of feature.

## Installation

For a manual installation, type this on your console:

```ruby
$ gem install votifier
```

## Usage

```ruby
require 'votifier'
server = Votifier::MinecraftServer.new(public_key_file, "some.minecraft-server.com")
votifier = Votifier::Client.new("MineList.kr", server)
votifier.send(username: "Notch")
```

If you have the player's IP addess and the timestamp, you can pass them

```ruby
require 'votifier'
server = Votifier::MinecraftServer.new(public_key_file, "some.minecraft-server.com:9999")
votifier = Votifier::Client.new("MineList.kr", server)
votifier.send(username: "Notch", ip_address: @ip_address, timestamp: @timestamp)
```

You can pass Key object to MinecraftServer initalizer directly. If you don't trust key, it is recommended to use this way.

```ruby
votifier_key = "KEY STRING"
pem_content = Votifier::Key.from_key_content(votifier_key, :public)
key = Votifier::Key.new(pem_content)
votifier_client = Votifier::Client.new("MineList.kr", server)
votifier_client.send(username: "Notch")
```

The MinecraftServer can receive the hostname/port in different ways:

```ruby
Votifier::MinecraftServer.new(public_key_file) => defaults to "localhost:8192"
Votifier::MinecraftServer.new(public_key_file, "some.minecraft-server.com") => port 8192
Votifier::MinecraftServer.new(public_key_file, 9999)  => defaults to "localhost"
Votifier::MinecraftServer.new(public_key_file, "some.minecraft-server.com:9999")
Votifier::MinecraftServer.new(public_key_file, "some.minecraft-server.com", 9999)
Votifier::MinecraftServer.new(public_key_file, 999, "some.minecraft-server.com")
server = Votifier::MinecraftServer.new(public_key_file)
server.host = "some.minecraft-server.com:9999"
```

For the server:

```ruby
require 'votifier'
Votifier::Server.new(private_key_file, '0.0.0.0:8193').listen
```

## TODO

* Unit Tests
* Adding Observer so custom class can perform tasks when a vote is received.
* Adding RDocs or Yard documentation
* Change the Server's constructor to accept hostname and port directly
* Add new class MinecraftPlayer (username, ip_address)
* Server should use start instead of listen

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
