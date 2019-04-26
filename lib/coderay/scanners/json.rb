module CodeRay
  module Scanners
    # Scanner for JSON (JavaScript Object Notation).
    class JSON < Scanner
      register_for :json
      file_extension 'json'

      KINDS_NOT_LOC = %i[
        float char content delimiter
        error integer operator value
      ].freeze # :nodoc:

      ESCAPE = / [bfnrt\\"\/] /x.freeze # :nodoc:
      UNICODE_ESCAPE = / u[a-fA-F0-9]{4} /x.freeze # :nodoc:
      KEY = / (?> (?: [^\\"]+ | \\. )* ) " \s* : /x.freeze

      protected

      def setup
        @state = :initial
      end

      # See http://json.org/ for a definition of the JSON lexic/grammar.
      def scan_tokens(encoder, options)
        state = options[:state] || @state

        encoder.begin_group state if %i[string key].include? state

        until eos?

          case state

          when :initial
            if match = scan(/ \s+ /x)
              encoder.text_token match, :space
            elsif match = scan(/"/)
              state = check(/#{KEY}/o) ? :key : :string
              encoder.begin_group state
              encoder.text_token match, :delimiter
            elsif match = scan(/ [:,\[{\]}] /x)
              encoder.text_token match, :operator
            elsif match = scan(/ true | false | null /x)
              encoder.text_token match, :value
            elsif match = scan(/ -? (?: 0 | [1-9]\d* ) /x)
              if scan(/ \.\d+ (?:[eE][-+]?\d+)? | [eE][-+]? \d+ /x)
                match << matched
                encoder.text_token match, :float
              else
                encoder.text_token match, :integer
              end
            else
              encoder.text_token getch, :error
            end

          when :string, :key
            if match = scan(/[^\\"]+/)
              encoder.text_token match, :content
            elsif match = scan(/"/)
              encoder.text_token match, :delimiter
              encoder.end_group state
              state = :initial
            elsif match = scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
              encoder.text_token match, :char
            elsif match = scan(/\\./m)
              encoder.text_token match, :content
            elsif match = scan(/ \\ | $ /x)
              encoder.end_group state
              encoder.text_token match, :error unless match.empty?
              state = :initial
            else
              raise_inspect format('else case " reached; %p not handled.', peek(1)), encoder
            end

          else
            raise_inspect format('Unknown state: %p', state), encoder

          end
        end

        @state = state if options[:keep_state]

        encoder.end_group state if %i[string key].include? state

        encoder
      end
    end
  end
end
