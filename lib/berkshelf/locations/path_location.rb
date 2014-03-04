module Berkshelf
  class PathLocation < Location::Base
    set_location_key :path
    set_valid_options :path, :metadata

    attr_accessor :path

    # @param [#to_s] dependency
    # @param [Solve::Constraint] version_constraint
    # @param [Hash] options
    #
    # @option options [#to_s] :path
    #   a filepath to the cookbook on your local disk
    # @option options [Buff::Boolean] :metadata
    #   true if this is a metadata source
    def initialize(dependency, options = {})
      super
      @path     = options[:path].to_s
      @metadata = options[:metadata]
    end

    def do_download
      CachedCookbook.from_path(path, name: name)
    end

    # Returns true if the location is a metadata location. By default, no
    # locations are the metadata location.
    #
    # @return [Buff::Boolean]
    def metadata?
      !!@metadata
    end

    # Return this PathLocation's path relative to the given target.
    #
    # @param [#to_s] target
    #   the path to a file or directory to be relative to
    #
    # @return [String]
    #   the relative path relative to the target
    def relative_path(target = '.')
      my_path     = Pathname.new(path).expand_path
      target_path = Pathname.new(target.to_s).expand_path
      target_path = target_path.dirname if target_path.file?

      new_path = my_path.relative_path_from(target_path).to_s

      return new_path if new_path.index('.') == 0
      "./#{new_path}"
    end

    #
    # The expanded path of this path on disk, relative to the berksfile.
    #
    # @return [String]
    #
    def expanded_path
      relative_path(dependency.berksfile.filepath)
    end

    # Valid if the path exists and is readable
    #
    # @return [Buff::Boolean]
    def valid?
      File.exist?(path) && File.readable?(path)
    end

    def to_hash
      super.merge(value: self.path)
    end

    def ==(other)
      other.is_a?(PathLocation) &&
      other.metadata? == metadata? &&
      other.expanded_path == expanded_path
    end

    def to_lock
      out =  "    path: #{relative_path(dependency.berksfile.filepath)}\n"
      out << "    metadata: true\n" if metadata?
      out
    end

    def to_s
      "source at #{relative_path(dependency.berksfile.filepath)}"
    end
  end
end
