require 'rotp/arguments'

module ROTP
  class CLI
    attr_reader :filename, :argv

    def initialize(filename, argv)
      @filename = filename
      @argv = argv
    end

    # :nocov:
    def run
      puts output
    end
    # :nocov:

    def errors
      if requires_secret? && blank_secret?
        return red 'You must also specify a --secret. Try --help for help.'
      end

      if secret_provided? && invalid_secret?
        return red 'Secret must be in RFC4648 Base32 format - http://en.wikipedia.org/wiki/Base32#RFC_4648_Base32_alphabet'
      end
    end

    def output
      options.warnings || errors || (help_message if options.mode == :help) || otp_value
    end

    def arguments
      @arguments ||= ROTP::Arguments.new(filename, argv)
    end

    def options
      arguments.options
    end

    def red(string)
      "\033[31m#{string}\033[0m"
    end

    private

    def help_message
      arguments.to_s
    end

    def otp_value
      case options.mode
      when :time
        ROTP::TOTP.new(options.secret, options.to_h).now
      when :hmac
        ROTP::HOTP.new(options.secret, options.to_h).at(options.counter)
      end
    end

    def requires_secret?
      %i[time hmac].include?(options.mode)
    end

    def secret_provided?
      !options.secret.to_s.empty?
    end

    def blank_secret?
      options.secret.to_s.empty?
    end

    def invalid_secret?
      options.secret.to_s.chars.any? { |c| ROTP::Base32::CHARS.index(c.upcase).nil? }
    end
  end
end
