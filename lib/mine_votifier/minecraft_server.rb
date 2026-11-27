module MineVotifier
  class MinecraftServer

    DEFAULT_HOSTNAME = 'localhost'
    DEFAULT_PORT     = 8192
    MAX_ENCRYPT_ATTEMPTS = 32

    IP_REGEXP = /\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/
    HOSTNAME_REGEXP = /(?!-)(?:[a-zA-Z0-9-]{0,62}[a-zA-Z0-9]\.)*(?!-)(?:[a-zA-Z0-9-]{1,62}[a-zA-Z0-9])/
    IP_OR_HOSTNAME_REGEXP = /\A(#{IP_REGEXP}|#{HOSTNAME_REGEXP})\z/
    IP_OR_HOSTNAME_WITH_PORT_REGEXP = /\A(#{IP_REGEXP.source}|#{HOSTNAME_REGEXP.source}):\d+\z/

    attr_accessor :hostname, :port, :public_key
    attr_reader :key

    def initialize(key, *args)
      raise 'The key parameter is required' unless !key.nil? && key != ""
      @key = MineVotifier::Key.import(key)
      raise 'MineVotifier::MinecraftServer#new accept 1 to 3 parameters only.' unless args.size <= 2
      self.send(:host=, *args)
    end

    def host=(*args)
      args.each do |arg|
        if arg.is_a?(Integer) || arg == arg.to_s.to_i.to_s
          @port = arg.to_i
        elsif arg.respond_to?(:to_s) && arg.to_s.match(IP_OR_HOSTNAME_REGEXP)
          @hostname = arg.to_s
        elsif arg.respond_to?(:to_s) && arg.to_s.match(IP_OR_HOSTNAME_WITH_PORT_REGEXP)
          @hostname, @port = arg.split(':')
          @port = @port.to_i
        else
          raise "Unexpected value: #{arg.inspect}"
        end
      end
      if @hostname.nil? || @hostname == ""
        @hostname = default_hostname
      end
      if @port.nil? || @port == ""
        @port = default_port
      end
    end

    def encrypt(votifier_string)
      MAX_ENCRYPT_ATTEMPTS.times do
        encrypted = key.public_encrypt(votifier_string)
        raise "Error encrypting, invalid size: #{encrypted.bytesize}" unless encrypted.bytesize == 256
        return encrypted unless collides_with_v2_prefix?(encrypted)
      end

      raise "Error encrypting, ciphertext collided with Votifier v2 prefix after #{MAX_ENCRYPT_ATTEMPTS} attempts"
    end

    def private_decrypt(encrypted)
      key.private_decrypt(encrypted)
    end

    def default_hostname
      DEFAULT_HOSTNAME
    end

    def default_port
      DEFAULT_PORT
    end

    private

    # Avoid Votifier v2 protocol detection prefixes in PKCS#1 v1.5 ciphertexts:
    # - 0x7B ('{'): treated as v2 JSON by VotifierPlus (<= 1.4.3), SimpleVote, TimberVoter
    # - 0x73 0x3A ("s:"): treated as v2 frame magic by NuVotifier, AzuVotifier, VotifierPlus (<= 1.4.3)
    def collides_with_v2_prefix?(encrypted)
      first_byte = encrypted.getbyte(0)
      first_byte == 0x7B || (first_byte == 0x73 && encrypted.getbyte(1) == 0x3A)
    end

  end
end
