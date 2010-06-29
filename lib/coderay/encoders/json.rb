module CodeRay
module Encoders
  
  # A simple JSON Encoder.
  # 
  # Example:
  #  CodeRay.scan('puts "Hello world!"', :ruby).json
  # yields
  #  [
  #    {"type"=>"text", "text"=>"puts", "kind"=>"ident"},
  #    {"type"=>"text", "text"=>" ", "kind"=>"space"},
  #    {"type"=>"block", "action"=>"open", "kind"=>"string"},
  #    {"type"=>"text", "text"=>"\"", "kind"=>"delimiter"},
  #    {"type"=>"text", "text"=>"Hello world!", "kind"=>"content"},
  #    {"type"=>"text", "text"=>"\"", "kind"=>"delimiter"},
  #    {"type"=>"block", "action"=>"close", "kind"=>"string"},
  #  ]
  class JSON < Encoder
    
    begin
      require 'json'
    rescue LoadError
      begin
        require 'rubygems'
        gem "json#{'-jruby' if defined? JRUBY_VERSION}"
        require 'json'
      rescue LoadError
        $stderr.puts "The JSON encoder needs the JSON library.\n" \
          "Please gem install json."
        raise
      end
    end
    
    register_for :json
    FILE_EXTENSION = 'json'
    
  protected
    def setup options
      @out = []
    end
    
    def finish options
      @out.to_json
    end
    
  public
    def text_token text, kind
      @out << { :type => 'text', :text => text, :kind => kind }
    end
    
    def begin_group kind
      @out << { :type => 'block', :action => 'open', :kind => kind }
    end
    
    def end_group kind
      @out << { :type => 'block', :action => 'close', :kind => kind }
    end
    
    def begin_line kind
      @out << { :type => 'block', :action => 'begin_line', :kind => kind }
    end
    
    def end_line kind
      @out << { :type => 'block', :action => 'end_line', :kind => kind }
    end
    
  end
  
end
end
