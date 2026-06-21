# frozen_string_literal: true

module RailsAgents
  GeneratedFile = Data.define(:file_id, :filename, :content_type, :data, :path) do
    def save(directory)
      dir = File.expand_path(directory)
      FileUtils.mkdir_p(dir)
      destination = File.join(dir, filename)
      File.binwrite(destination, data)
      self.class.new(file_id:, filename:, content_type:, data:, path: destination)
    end

    def size = data.bytesize
  end
end
