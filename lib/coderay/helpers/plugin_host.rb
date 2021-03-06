module CodeRay
  # = PluginHost
  #
  # A simple subclass/subfolder plugin system.
  #
  # Example:
  #  class Generators
  #    extend PluginHost
  #    plugin_path 'app/generators'
  #  end
  #
  #  class Generator
  #    extend Plugin
  #    PLUGIN_HOST = Generators
  #  end
  #
  #  class FancyGenerator < Generator
  #    register_for :fancy
  #  end
  #
  #  Generators[:fancy]  #-> FancyGenerator
  #  # or
  #  CodeRay.require_plugin 'Generators/fancy'
  #  # or
  #  Generators::Fancy
  module PluginHost
    # Raised if Encoders::[] fails because:
    # * a file could not be found
    # * the requested Plugin is not registered
    PluginNotFound = Class.new LoadError
    HostNotFound   = Class.new LoadError

    PLUGIN_HOSTS = []
    PLUGIN_HOSTS_BY_ID = {} # dummy hash

    # Loads all plugins using list and load.
    def load_all
      list.each do |plugin|
        load plugin
      end
    end

    # Returns the Plugin for +id+.
    #
    # Example:
    #  yaml_plugin = MyPluginHost[:yaml]
    def [](id, *args, &blk)
      plugin = validate_id(id)
      begin
        plugin = plugin_hash.[](plugin, *args, &blk)
      end while plugin.is_a? String
      plugin
    end

    alias load []

    # Tries to +load+ the missing plugin by translating +const+ to the
    # underscore form (eg. LinesOfCode becomes lines_of_code).
    def const_missing(const)
      id = const.to_s
                .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                .downcase
      load id
    end

    class << self
      # Adds the module/class to the PLUGIN_HOSTS list.
      def extended(mod)
        PLUGIN_HOSTS << mod
      end
    end

    # The path where the plugins can be found.
    def plugin_path(*args)
      @plugin_path = File.expand_path File.join(*args) unless args.empty?
      @plugin_path ||= ''
    end

    # Map a plugin_id to another.
    #
    # Usage: Put this in a file plugin_path/_map.rb.
    #
    #  class MyColorHost < PluginHost
    #    map :navy => :dark_blue,
    #      :maroon => :brown,
    #      :luna => :moon
    #  end
    def map(hash)
      hash.each do |from, to|
        from = validate_id from
        to   = validate_id to
        plugin_hash[from] = to unless plugin_hash.key? from
      end
    end

    # Define the default plugin to use when no plugin is found
    # for a given id, or return the default plugin.
    #
    # See also map.
    #
    #  class MyColorHost < PluginHost
    #    map :navy => :dark_blue
    #    default :gray
    #  end
    #
    #  MyColorHost.default  # loads and returns the Gray plugin
    def default(id = nil)
      if id
        id = validate_id id
        raise "The default plugin can't be named \"default\"." if id == :default

        plugin_hash[:default] = id
      else
        load :default
      end
    end

    # Every plugin must register itself for +id+ by calling register_for,
    # which calls this method.
    #
    # See Plugin#register_for.
    def register(plugin, id)
      plugin_hash[validate_id(id)] = plugin
    end

    # A Hash of plugion_id => Plugin pairs.
    def plugin_hash
      @plugin_hash ||= (@plugin_hash = make_plugin_hash).tap { load_plugin_map }
    end

    # Returns an array of all .rb files in the plugin path.
    #
    # The extension .rb is not included.
    def list
      Dir[path_to('*')].select do |file|
        File.basename(file)[/^(?!_)\w+\.rb$/]
      end.map do |file|
        File.basename(file, '.rb').to_sym
      end
    end

    # Returns an array of all Plugins.
    #
    # Note: This loads all plugins using load_all.
    def all_plugins
      load_all
      plugin_hash.values.grep(Class)
    end

    # Loads the map file (see map).
    #
    # This is done automatically when plugin_path is called.
    def load_plugin_map
      mapfile = path_to '_map'
      if File.exist? mapfile
        require mapfile
        true
      else
        false
      end
    end

    protected

    # Return a plugin hash that automatically loads plugins.
    def make_plugin_hash
      Hash.new do |h, plugin_id|
        id = validate_id(plugin_id)
        path = path_to id
        begin
          require path
        rescue LoadError => e
          raise PluginNotFound, format('%p could not load plugin %p: %s', self, id, e) unless h.key?(:default)

          h[:default] if h.key?(:default)
        else
          # Plugin should have registered by now
          raise PluginNotFound, "No #{name} plugin for #{id.inspect} found in #{path}." unless h.key?(id)

          h[id] if h.key?(id)
        end
      end
    end

    # Returns the expected path to the plugin file for the given id.
    def path_to(plugin_id)
      File.join plugin_path, "#{plugin_id}.rb"
    end

    # Converts +id+ to a valid plugin ID String, or returns +nil+.
    #
    # Raises +ArgumentError+ for all other objects, or if the
    # given String includes non-alphanumeric characters (\W).
    def validate_id(id)
      case id
      when Symbol
        id.to_s
      when String
        raise ArgumentError, "Invalid id given: #{id}" unless id[/\w+/] == id

        id.downcase if id[/\w+/] == id
      else
        raise ArgumentError, "Symbol or String expected, but #{id.class} given."
      end
    end
  end
end
