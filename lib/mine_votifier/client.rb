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
      validate_service_name!(service_name)

      @service_name     = service_name
      @minecraft_server = minecraft_server
      @timeout          = timeout
    end

    # Sends a vote packet encrypted via the MinecraftServer and over TCP.
    # @param username [String, nil] the username to vote for (2-16 characters)
    # @param ip_address [String, nil] the IP address of the voter, defaults to 127.0.0.1 if nil
    # @param timestamp [Integer, nil] UNIX timestamp for the vote
    # @raise [ValidationError] if service_name/username/ip_address include a newline
    # @raise [ValidationError] if username is nil or not 2-16 characters
    # @raise [ReadTimeoutError] if server read does not complete before timeout
    # @return [void]
    def send_vote(username: nil, ip_address: nil, timestamp: nil)
      validate_username!(username)
      validate_ip_address!(ip_address)

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
    # @raise [ReadTimeoutError] if server read does not complete before timeout
    # @return [void]
    def send_to_server(encrypted)
      Socket.tcp(
        minecraft_server.hostname,
        minecraft_server.port,
        connect_timeout: timeout
      ) do |sock|
        sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        sock.write(encrypted)
        sock.flush
        sock.close_write

        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

        loop do
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise ReadTimeoutError, "socket read timed out (reason=remaining<=0, remaining=#{remaining})" if remaining <= 0

          ready = IO.select([sock], nil, nil, remaining)
          # IO.select timeout (nil) means no read event was observed within remaining time.
          raise ReadTimeoutError, "socket read timed out (reason=io_select_timeout, remaining=#{remaining})" unless ready

          begin
            # FIN from peer is surfaced as EOFError by read_nonblock, handled below.
            sock.read_nonblock(256)
          rescue IO::WaitReadable
            next
          end
        end
      end
    rescue EOFError
      # Peer half-closed (TCP FIN) and no further data is readable.
    end

    # Validates service name safety.
    # @param name [String] the service name to validate
    # @raise [ValidationError] when service name is nil/empty or includes a newline
    # @return [void]
    def validate_service_name!(name)
      raise ValidationError, "service_name should not be empty" if name.nil? || name.empty?
      validate_no_newline!("service_name", name)
    end

    # Validates username safety.
    # @param name [String, nil] the username to validate
    # @raise [ValidationError] when username is nil, out of length range, or includes a newline
    # @return [void]
    def validate_username!(name)
      raise ValidationError, "username should not empty: #{name.inspect}" if name.nil?
      raise ValidationError, "username length should be 2..16: #{name.inspect}" unless (2..16).cover?(name.length)

      validate_no_newline!("username", name)
    end

    # Validates ip address safety.
    # @param address [String, nil] the ip address to validate
    # @raise [ValidationError] when ip address includes a newline
    # @return [void]
    def validate_ip_address!(address)
      return if address.nil?
      validate_no_newline!("ip_address", address)
    end

    # Validates protocol field safety against newline injection.
    # @param field [String] field name for error message
    # @param value [String] field value to validate
    # @raise [ValidationError] when value includes CR/LF
    # @return [void]
    def validate_no_newline!(field, value)
      return unless value.include?("\n") || value.include?("\r")

      raise ValidationError, "#{field} should not include CR/LF: #{value.inspect}"
    end
  end


  # Raised when socket read exceeds configured timeout.
  class ReadTimeoutError < StandardError; end

  # Raised when validation fails in Votifier client.
  class ValidationError < StandardError; end
end
