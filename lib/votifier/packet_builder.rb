# lib/votifier/packet_builder.rb
module Votifier
  # Builds the Votifier packet string from provided options.
  class PacketBuilder
    # @param service_name [String] the Votifier service name
    # @param opts [Hash] options for packet fields
    # @option opts [String] :username the username
    # @option opts [String] :ip_address the voter's IP address
    # @option opts [Integer] :timestamp the UNIX timestamp
    def initialize(service_name, opts = {})
      @service_name = service_name
      @opts         = opts
    end

    # Constructs the Votifier packet string.
    # @return [String] newline-separated packet fields
    def build
      [
        "VOTE",
        @service_name,
        @opts[:username]   || "",
        @opts[:ip_address] || "127.0.0.1",
        @opts[:timestamp]  || Time.now.to_i
      ].join("\n")
    end
  end
end
