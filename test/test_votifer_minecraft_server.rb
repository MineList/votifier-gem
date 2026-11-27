require 'test/unit'
require 'votifier'

class VotifierMinecraftServerTest < Test::Unit::TestCase

  def setup
    @public_key = File.expand_path('../../config/sample-public.pem', __FILE__)
    @private_key = File.expand_path('../../config/sample-private.pem', __FILE__)
  end

  def test_public_key_works
    server = MineVotifier::MinecraftServer.new(@public_key)
    assert_not_equal "", server.encrypt("random_string_to_encode")
  end

  def test_private_key_works
    server = MineVotifier::MinecraftServer.new(@private_key)
    assert_not_equal "", server.encrypt("random_string_to_encode")
  end

  def test_ip_with_port_in_one_string
    server = MineVotifier::MinecraftServer.new(@private_key, '1.1.1.1:99')
    assert_equal '1.1.1.1', server.hostname
    assert_equal 99, server.port
  end

  def test_ip_with_port_separate
    server = MineVotifier::MinecraftServer.new(@private_key, '1.1.1.1', 99)
    assert_equal '1.1.1.1', server.hostname
    assert_equal 99, server.port
  end

  def test_hostname_with_port_separate
    server = MineVotifier::MinecraftServer.new(@private_key, 'some.minecraft-server.com', 99)
    assert_equal 'some.minecraft-server.com', server.hostname
    assert_equal 99, server.port
  end

  def test_opposite_order
    server = MineVotifier::MinecraftServer.new(@private_key, 99, 'some.minecraft-server.com')
    assert_equal 'some.minecraft-server.com', server.hostname
    assert_equal 99, server.port
  end

  def test_port_can_be_a_string_too
    server = MineVotifier::MinecraftServer.new(@private_key, 'some.minecraft-server.com', '99')
    assert_equal 'some.minecraft-server.com', server.hostname
    assert_equal 99, server.port
  end

  def test_using_host
    server = MineVotifier::MinecraftServer.new(@private_key)
    server.host = '1.1.1.1:99'
    assert_equal '1.1.1.1', server.hostname
    assert_equal 99, server.port
  end

  def test_encrypt_retries_when_ciphertext_collides_with_v2_prefixes
    server = MineVotifier::MinecraftServer.new(@public_key)
    colliding_json = "\x7B".b + ("\x00".b * 255)
    colliding_v2_frame = "\x73\x3A".b + ("\x00".b * 254)
    safe_ciphertext = "\x42".b + ("\x00".b * 255)

    responses = [colliding_json, colliding_v2_frame, safe_ciphertext]
    calls = 0
    server.key.define_singleton_method(:public_encrypt) do |_payload|
      calls += 1
      responses.shift
    end

    result = server.encrypt("VOTE\nTesting\nNotch\n127.0.0.1\n1234567890")
    assert_equal safe_ciphertext, result
    assert_equal 3, calls
  end

  def test_encrypt_accepts_0x73_when_second_byte_is_not_0x3a
    server = MineVotifier::MinecraftServer.new(@public_key)
    safe_ciphertext = "\x73\x3B".b + ("\x00".b * 254)

    calls = 0
    server.key.define_singleton_method(:public_encrypt) do |_payload|
      calls += 1
      safe_ciphertext
    end

    result = server.encrypt("VOTE\nTesting\nNotch\n127.0.0.1\n1234567890")
    assert_equal safe_ciphertext, result
    assert_equal 1, calls
  end

  def test_encrypt_raises_when_max_attempts_exceeded
    server = MineVotifier::MinecraftServer.new(@public_key)
    colliding_json = "\x7B".b + ("\x00".b * 255)

    calls = 0
    server.key.define_singleton_method(:public_encrypt) do |_payload|
      calls += 1
      colliding_json
    end

    error = assert_raise(RuntimeError) do
      server.encrypt("VOTE\nTesting\nNotch\n127.0.0.1\n1234567890")
    end
    assert_equal MineVotifier::MinecraftServer::MAX_ENCRYPT_ATTEMPTS, calls
    assert_match(/Votifier v2 prefix/, error.message)
  end

  def test_encrypt_raises_on_invalid_ciphertext_size
    server = MineVotifier::MinecraftServer.new(@public_key)

    calls = 0
    server.key.define_singleton_method(:public_encrypt) do |_payload|
      calls += 1
      "\x42".b * 128
    end

    error = assert_raise(RuntimeError) do
      server.encrypt("VOTE\nTesting\nNotch\n127.0.0.1\n1234567890")
    end
    assert_equal 1, calls
    assert_match(/invalid size: 128/, error.message)
  end

  def test_encrypt_with_sample_rsa_keys_is_decryptable_and_avoids_v2_prefixes
    public_server = MineVotifier::MinecraftServer.new(@public_key)
    private_server = MineVotifier::MinecraftServer.new(@private_key)
    payload = "VOTE\nTesting\nNotch\n127.0.0.1\n1234567890"

    50.times do
      encrypted = public_server.encrypt(payload)
      assert_equal 256, encrypted.bytesize
      assert_equal Encoding::ASCII_8BIT, encrypted.encoding
      assert_not_equal 0x7B, encrypted.getbyte(0)
      assert !(encrypted.getbyte(0) == 0x73 && encrypted.getbyte(1) == 0x3A)
      assert_equal payload, private_server.private_decrypt(encrypted)
    end
  end

end
