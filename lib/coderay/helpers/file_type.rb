module CodeRay
  # = FileType
  #
  # A simple filetype recognizer.
  #
  # == Usage
  #
  #  # determine the type of the given
  #  lang = FileType[file_name]
  #
  #  # return :text if the file type is unknown
  #  lang = FileType.fetch file_name, :text
  #
  #  # try the shebang line, too
  #  lang = FileType.fetch file_name, :text, true
  module FileType
    UnknownFileType = Class.new Exception

    class << self
      # Try to determine the file type of the file.
      #
      # +filename+ is a relative or absolute path to a file.
      #
      # The file itself is only accessed when +read_shebang+ is set to true.
      # That means you can get filetypes from files that don't exist.
      def [](filename, read_shebang = false)
        name = File.basename filename
        ext = File.extname(name).sub(/^\./, '') # from last dot, delete the leading dot
        ext2 = filename.to_s[/\.(.*)/, 1] # from first dot

        type =
          TYPE_FROM_EXT[ext] ||
          TYPE_FROM_EXT[ext.downcase] ||
          (TYPE_FROM_EXT[ext2] if ext2) ||
          (TYPE_FROM_EXT[ext2.downcase] if ext2) ||
          TYPE_FROM_NAME[name] ||
          TYPE_FROM_NAME[name.downcase]
        type ||= type_from_shebang(filename) if read_shebang

        type
      end

      # This works like Hash#fetch.
      #
      # If the filetype cannot be found, the +default+ value
      # is returned.
      def fetch(filename, default = nil, read_shebang = false)
        warn 'Block supersedes default value argument; use either.' if default && block_given?

        if type = self[filename, read_shebang]
          type
        else
          return yield if block_given?
          return default if default

          raise UnknownFileType, format('Could not determine type of %p.', filename)
        end
      end

      protected

      def type_from_shebang(filename)
        return unless File.exist? filename

        File.open filename, 'r' do |f|
          if first_line = f.gets
            if type = first_line[TYPE_FROM_SHEBANG]
              type.to_sym
            end
          end
        end
      end
    end

    TYPE_FROM_EXT = {
      'c' => :c,
      'cfc' => :xml,
      'cfm' => :xml,
      'clj' => :clojure,
      'css' => :css,
      'diff' => :diff,
      'dpr' => :delphi,
      'erb' => :erb,
      'gemspec' => :ruby,
      'go' => :go,
      'groovy' => :groovy,
      'gvy' => :groovy,
      'h' => :c,
      'haml' => :haml,
      'htm' => :html,
      'html' => :html,
      'html.erb' => :erb,
      'java' => :java,
      'js' => :java_script,
      'json' => :json,
      'lua' => :lua,
      'mab' => :ruby,
      'pas' => :delphi,
      'patch' => :diff,
      'phtml' => :php,
      'php' => :php,
      'php3' => :php,
      'php4' => :php,
      'php5' => :php,
      'prawn' => :ruby,
      'py' => :python,
      'py3' => :python,
      'pyw' => :python,
      'rake' => :ruby,
      'raydebug' => :raydebug,
      'rb' => :ruby,
      'rbw' => :ruby,
      'rhtml' => :erb,
      'rjs' => :ruby,
      'rpdf' => :ruby,
      'ru' => :ruby, # config.ru
      'rxml' => :ruby,
      'sass' => :sass,
      'sql' => :sql,
      'taskpaper' => :taskpaper,
      'template' => :json, # AWS CloudFormation template
      'tmproj' => :xml,
      'xaml' => :xml,
      'xhtml' => :html,
      'xml' => :xml,
      'yaml' => :yaml,
      'yml' => :yaml,
      'cc' => :cpp, 'cpp' => :cpp, 'cp' => :cpp, 'cxx' => :cpp, 'c++' => :cpp, 'C' => :cpp, 'hh' => :cpp, 'hpp' => :cpp, 'h++' => :cpp, 'cu' => :cpp
    }.freeze

    TYPE_FROM_SHEBANG = /\b(?:ruby|perl|python|sh)\b/.freeze

    TYPE_FROM_NAME = {
      'Capfile' => :ruby,
      'Rakefile' => :ruby,
      'Rantfile' => :ruby,
      'Gemfile' => :ruby,
      'Guardfile' => :ruby,
      'Vagrantfile' => :ruby,
      'Appraisals' => :ruby
    }.freeze
  end
end
