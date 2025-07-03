require 'socket'

module MineVotifier
  # Client for sending votes to a Votifier server using TCP sockets.
  class Client
    DEFAULT_TIMEOUT = 5

    # @return [String] the Votifier service name
    attr_reader :service_name
    # @return [Object] the MinecraftServer instance providing hostname, port, and encryption
    attr_reader :minecraft_server
    # @return [Integer] socket connect timeout in seconds
    attr_reader :timeout

    # @param service_name [String] the name of the Votifier service
    # @param minecraft_server [#hostname, #port, #encrypt] server details and encryption provider
    # @param timeout [Integer] connection timeout in seconds (defaults to DEFAULT_TIMEOUT)
    def initialize(service_name:, minecraft_server:, timeout: DEFAULT_TIMEOUT)
      @service_name     = service_name
      @minecraft_server = minecraft_server
      @timeout          = timeout
    end

    # Sends a vote packet encrypted via the MinecraftServer and over TCP.
    # @param username [String, nil] the username to vote for (2-16 characters)
    # @param ip_address [String, nil] the IP address of the voter, defaults to 127.0.0.1 if nil
    # @param timestamp [Integer, nil] UNIX timestamp for the vote
    # @raise [ValidationError] if username length is invalid
    # @return [void]
    def send_vote(username: nil, ip_address: nil, timestamp: nil)
      validate_username!(username)

      packet = MineVotifier::PacketBuilder.new(
        service_name,
        username:   username,
        ip_address: ip_address,
        timestamp:  timestamp
      ).build

      encrypted = minecraft_server.encrypt(packet)
      send_to_server(encrypted)
    end

    private

    # Opens a new TCP socket to the configured server and sends encrypted data.
    # Socket is automatically closed when the block ends.
    # @param encrypted [String] the encrypted packet to send
    # @return [void]
    def send_to_server(encrypted)
      Socket.tcp(
        minecraft_server.hostname,
        minecraft_server.port,
        connect_timeout: timeout
      ) do |sock|
        sock.print(encrypted)
      end
    end

    # Validates the username length if provided.
    # @param name [String, nil] the username to validate
    # @raise [ValidationError] when username is not nil and length is not between 2 and 16
    # @return [void]
    def validate_username!(name)
      return if name.nil? || name.size.between?(2, 16)
      raise ValidationError, "username must be between 2 and 16 characters: \#{name.inspect}"
    end
  end

  # Raised when validation fails in Votifier client.
  class ValidationError < StandardError; end
end
