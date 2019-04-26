module CodeRay
  module Scanners
    class CSS < Scanner
      register_for :css

      KINDS_NOT_LOC = %i[
        comment
        class pseudo_class tag
        id directive
        key value operator color float string
        error important type
      ].freeze # :nodoc:

      module RE # :nodoc:
        Hex = /[0-9a-fA-F]/.freeze
        Unicode = /\\#{Hex}{1,6}\b/.freeze # differs from standard because it allows uppercase hex too
        Escape = /#{Unicode}|\\[^\n0-9a-fA-F]/.freeze
        NMChar = /[-_a-zA-Z0-9]/.freeze
        NMStart = /[_a-zA-Z]/.freeze
        String1 = /"(?:[^\n\\"]+|\\\n|#{Escape})*"?/.freeze  # TODO: buggy regexp
        String2 = /'(?:[^\n\\']+|\\\n|#{Escape})*'?/.freeze  # TODO: buggy regexp
        String = /#{String1}|#{String2}/.freeze

        HexColor = /#(?:#{Hex}{6}|#{Hex}{3})/.freeze

        Num = /-?(?:[0-9]*\.[0-9]+|[0-9]+)n?/.freeze
        Name = /#{NMChar}+/.freeze
        Ident = /-?#{NMStart}#{NMChar}*/.freeze
        AtKeyword = /@#{Ident}/.freeze
        Percentage = /#{Num}%/.freeze

        reldimensions = %w[em ex px]
        absdimensions = %w[in cm mm pt pc]
        Unit = Regexp.union(*(reldimensions + absdimensions + %w[s dpi dppx deg]))

        Dimension = /#{Num}#{Unit}/.freeze

        Function = /(?:url|alpha|attr|counters?)\((?:[^)\n]|\\\))*\)?/.freeze

        Id = /(?!#{HexColor}\b(?!-))##{Name}/.freeze
        Class = /\.#{Name}/.freeze
        PseudoClass = /::?#{Ident}/.freeze
        AttributeSelector = /\[[^\]]*\]?/.freeze
      end

      protected

      def setup
        @state = :initial
        @value_expected = false
      end

      def scan_tokens(encoder, options)
        states = Array(options[:state] || @state).dup
        value_expected = @value_expected

        until eos?

          if match = scan(/\s+/)
            encoder.text_token match, :space

          elsif case states.last
                when :initial, :media
                  if match = scan(/(?>#{RE::Ident})(?!\()|\*/ox)
                    encoder.text_token match, :tag
                    next
                  elsif match = scan(RE::Class)
                    encoder.text_token match, :class
                    next
                  elsif match = scan(RE::Id)
                    encoder.text_token match, :id
                    next
                  elsif match = scan(RE::PseudoClass)
                    encoder.text_token match, :pseudo_class
                    next
                  elsif match = scan(RE::AttributeSelector)
                    # TODO: Improve highlighting inside of attribute selectors.
                    encoder.text_token match[0, 1], :operator
                    encoder.text_token match[1..-2], :attribute_name if match.size > 2
                    encoder.text_token match[-1, 1], :operator if match[-1] == ']'
                    next
                  elsif match = scan(/@media/)
                    encoder.text_token match, :directive
                    states.push :media_before_name
                    next
                  end

                when :block
                  if match = scan(/(?>#{RE::Ident})(?!\()/ox)
                    if value_expected
                      encoder.text_token match, :value
                    else
                      encoder.text_token match, :key
                    end
                    next
                  end

                when :media_before_name
                  if match = scan(RE::Ident)
                    encoder.text_token match, :type
                    states[-1] = :media_after_name
                    next
                  end

                when :media_after_name
                  if match = scan(/\{/)
                    encoder.text_token match, :operator
                    states[-1] = :media
                    next
                  end

                else
              #:nocov:
                  raise_inspect 'Unknown state', encoder
              #:nocov:

            end

          elsif match = scan(%r{/\*(?:.*?\*/|\z)}m)
            encoder.text_token match, :comment

          elsif match = scan(/\{/)
            value_expected = false
            encoder.text_token match, :operator
            states.push :block

          elsif match = scan(/\}/)
            value_expected = false
            encoder.text_token match, :operator
            states.pop if states.last == :block || states.last == :media

          elsif match = scan(/#{RE::String}/o)
            encoder.begin_group :string
            encoder.text_token match[0, 1], :delimiter
            encoder.text_token match[1..-2], :content if match.size > 2
            encoder.text_token match[-1, 1], :delimiter if match.size >= 2
            encoder.end_group :string

          elsif match = scan(/#{RE::Function}/o)
            encoder.begin_group :function
            start = match[/^\w+\(/]
            encoder.text_token start, :delimiter
            if match[-1] == ')'
              encoder.text_token match[start.size..-2], :content if match.size > start.size + 1
              encoder.text_token ')', :delimiter
            else
              encoder.text_token match[start.size..-1], :content if match.size > start.size
            end
            encoder.end_group :function

          elsif match = scan(/(?: #{RE::Dimension} | #{RE::Percentage} | #{RE::Num} )/ox)
            encoder.text_token match, :float

          elsif match = scan(/#{RE::HexColor}/o)
            encoder.text_token match, :color

          elsif match = scan(/! *important/)
            encoder.text_token match, :important

          elsif match = scan(/(?:rgb|hsl)a?\([^()\n]*\)?/)
            encoder.text_token match, :color

          elsif match = scan(RE::AtKeyword)
            encoder.text_token match, :directive

          elsif match = scan(%r{ [+>~:;,.=()/] }x)
            if match == ':'
              value_expected = true
            elsif match == ';'
              value_expected = false
            end
            encoder.text_token match, :operator

          else
            encoder.text_token getch, :error

          end

        end

        if options[:keep_state]
          @state = states
          @value_expected = value_expected
        end

        encoder
      end
    end
  end
end
