module CodeRay
  module Encoders
    # = Lint Encoder
    #
    # Checks for:
    #
    # - empty tokens
    # - incorrect nesting
    #
    # It will raise an InvalidTokenStream exception when any of the above occurs.
    #
    # See also: Encoders::DebugLint
    class Lint < Debug
      register_for :lint

      InvalidTokenStream         = Class.new StandardError
      EmptyToken                 = Class.new InvalidTokenStream
      UnknownTokenKind           = Class.new InvalidTokenStream
      IncorrectTokenGroupNesting = Class.new InvalidTokenStream

      def text_token(text, kind)
        raise EmptyToken,       format('empty token for %p', kind) if text.empty?
        raise UnknownTokenKind, format('unknown token kind %p (text was %p)', kind, text) unless TokenKinds.key? kind
      end

      def begin_group(kind)
        @opened << kind
      end

      def end_group(kind)
        raise IncorrectTokenGroupNesting, format('We are inside %s, not %p (end_group)', @opened.reverse.map(&:inspect).join(' < '), kind) if @opened.last != kind

        @opened.pop
      end

      def begin_line(kind)
        @opened << kind
      end

      def end_line(kind)
        raise IncorrectTokenGroupNesting, format('We are inside %s, not %p (end_line)', @opened.reverse.map(&:inspect).join(' < '), kind) if @opened.last != kind

        @opened.pop
      end

      protected

      def setup(_options)
        @opened = []
      end

      def finish(_options)
        raise format('Some tokens still open at end of token stream: %p', @opened) unless @opened.empty?
      end
    end
  end
end
