module CodeRay
module Encoders
  # = XML Encoder
  #
  # Uses REXML. Very slow.
  class XML < Encoder
    register_for :xml

    FILE_EXTENSION = 'xml'.freeze

    autoload :REXML, 'rexml/document'

    DEFAULT_OPTIONS = {
      :tab_width => 8,
      :pretty => -1,
      :transitive => false
    }.freeze

    protected

    def setup(options)
      super

      @doc = REXML::Document.new
      @doc << REXML::XMLDecl.new
      @tab_width = options[:tab_width]
      @root = @node = @doc.add_element('coderay-tokens')
    end

    def finish(options)
      @doc.write @out, options[:pretty], options[:transitive], true

      super
    end

    public

    def text_token(text, kind)
      token = if kind == :space
        @node
              else
        @node.add_element kind.to_s
              end
      text.scan(/(\x20+)|(\t+)|(\n)|[^\x20\t\n]+/) do |space, tab, nl|
        token << if space
          REXML::Text.new(space, true)
                 elsif tab
          REXML::Text.new(tab, true)
                 elsif nl
          REXML::Text.new(nl, true)
                 else
          REXML::Text.new($&)
                 end
      end
    end

    def begin_group(kind)
      @node = @node.add_element kind.to_s
    end

    def end_group(_kind)
      raise 'no token to close!' if @node == @root

      @node = @node.parent
    end
  end
end
end
