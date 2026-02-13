require 'test/unit'
require 'ipaddr'
require 'votifier'

class VotifierClientValidationTest < Test::Unit::TestCase
  FakeServer = Struct.new(:hostname, :port) do
    def encrypt(packet)
      packet
    end
  end

  def build_client
    server = FakeServer.new('127.0.0.1', 8192)
    client = MineVotifier::Client.new(service_name: 'Testing', minecraft_server: server)
    client.define_singleton_method(:send_to_server) { |_encrypted| nil }
    client
  end

  def test_non_string_ip_address_raises_validation_error
    client = build_client

    assert_raise(MineVotifier::ValidationError) do
      client.send_vote(username: 'Notch', ip_address: IPAddr.new('127.0.0.1'))
    end
  end

  def test_ip_address_with_newline_raises_validation_error
    client = build_client

    assert_raise(MineVotifier::ValidationError) do
      client.send_vote(username: 'Notch', ip_address: "127.0.0.1\nmalicious")
    end
  end

  def test_ip_address_with_carriage_return_raises_validation_error
    client = build_client

    assert_raise(MineVotifier::ValidationError) do
      client.send_vote(username: 'Notch', ip_address: "127.0.0.1\rmalicious")
    end
  end

  def test_normal_ip_address_string_is_still_valid
    client = build_client

    assert_nothing_raised do
      client.send_vote(username: 'Notch', ip_address: '127.0.0.1')
    end
  end

  def test_single_character_username_is_valid
    client = build_client

    assert_nothing_raised do
      client.send_vote(username: 'N')
    end
  end

  def test_empty_username_is_valid
    client = build_client

    assert_nothing_raised do
      client.send_vote(username: '')
    end
  end

  def test_username_longer_than_16_characters_raises_validation_error
    client = build_client

    assert_raise(MineVotifier::ValidationError) do
      client.send_vote(username: 'a' * 17)
    end
  end
end
