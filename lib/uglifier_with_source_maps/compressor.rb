module UglifierWithSourceMaps
  class Compressor
    def self.call(*args)
      new.call(*args)
    end

    def initialize(options = {})
      @uglifier = Uglifier.new(options)
      # @cache_key = [
      #     'UglifierWithSourceMapsCompressor',
      #     ::Uglifier::VERSION,
      #     ::UglifierWithSourceMaps::VERSION,
      #     options
      #   ]
    end

    def compress(data, context)

      minified_data, sourcemap = @uglifier.compile_with_map(data)

      digest_value = digest(minified_data)

      # write source map
      minified_filename     = File.join(Rails.application.config.assets.prefix, "#{context.logical_path}-#{digest_value}.js")
      sourcemap_filename    = File.join(Rails.application.config.assets.sourcemaps_prefix, "#{context.logical_path}-#{digest_value}.map")
      concatenated_filename = File.join(Rails.application.config.assets.uncompressed_prefix, "#{context.logical_path}-#{digest_value}.js")

      sourcemap_path = File.join(Rails.root, 'tmp', sourcemap_filename)
      unminified_path = File.join(Rails.root, 'tmp', concatenated_filename)

      FileUtils.mkdir_p File.dirname(sourcemap_path)
      FileUtils.mkdir_p File.dirname(unminified_path)

      # Write sourcemap and uncompressed js
      unless File.exists?(sourcemap_path)
        map = JSON.parse(sourcemap)
        map['file']    = minified_filename
        map['sources'] = [concatenated_filename]
        map['sourcesContent'] = data
        File.open(sourcemap_path, "w") { |f| f.puts map.to_json }
      end

      unless File.exists?(unminified_path)
        File.open(unminified_path, "w") {|f| f.write(data)}
      end

      # we don't include the source map (we don't want raw sources public, and it screws up the digest of the final js file)
      return minified_data
    end

    def digest(io)
      Rails.application.assets.digest.update(io).hexdigest
    end
  end
end





