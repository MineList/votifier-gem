require 'test/unit'
require 'votifier'
require 'minitest/mock'

class VotifierClientTest < Test::Unit::TestCase

  def setup
    @socket_mock = MiniTest::Mock.new
    expected_open_args = [
      MineVotifier::MinecraftServer::DEFAULT_HOSTNAME,
      MineVotifier::MinecraftServer::DEFAULT_PORT
    ]
    @socket_mock.expect(:open, @socket_mock, expected_open_args)
    @socket_mock.expect(:print, 256, [String])
    @socket_mock.expect(:close, nil)
    @public_key_file = File.expand_path('../../config/sample-public.key', __FILE__)
  end

  def test_votifier_client_default
    server = MineVotifier::MinecraftServer.new(@public_key_file)
    client = MineVotifier::Client.new(
      service_name:     "Testing",
      minecraft_server: server
    )
    client.send_vote
    assert @socket_mock.verify
  end

  def test_votifier_client_username
    server = MineVotifier::MinecraftServer.new(@public_key_file)
    client = MineVotifier::Client.new(
      service_name:     "Testing",
      minecraft_server: server
    )
    client.send_vote(username: "Notch")
    assert @socket_mock.verify
  end

  def test_votifier_client_postpone_setting_hostname_port
    server = MineVotifier::MinecraftServer.new(@public_key_file, "some.mincraft-server.com")
    client = MineVotifier::Client.new(
      service_name:     "Testing",
      minecraft_server: server
    )
    @socket_mock.expect(:open, @socket_mock, [server.hostname, server.port])
    client.send_vote(username: "Notch")
    assert @socket_mock.verify
  end

end
