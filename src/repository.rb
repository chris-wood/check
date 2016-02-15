require 'digest'

class Repository
    attr_reader :path
    attr_reader :thread

    attr_reader :repo_data
    attr_writer :repo_data

    def initialize(path)
        @path = path
        @abs_path = File.join(path, DEFAULT_FNAME)
        if not File.exists?(@abs_path) then
            File.new(@abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)

            @repo_data = {}
            @repo_data[:digest] = self.get_repo_digest()
            File.open(@abs_path, 'w') {|f| f.write YAML::dump(@repo_data) }
        else
            @repo_data = YAML::load_file(@abs_path)
        end

        puts repo_data.to_s
    end

    def get_repo_digest()
        files = Dir["#{@path}/.git/*"].reject{|f| File.directory?(f)}
        content = files.map{|f| File.read(f)}.join
        return Digest::SHA256.digest(content).to_s
    end

    def has_changed()
        digest = self.get_repo_digest()
        old_digest = repo_data[:digest]
        repo_data[:digest] = digest
        return digest != old_digest
    end

    def dump()
        File.open(@abs_path, 'w') {|f| f.write YAML::dump(@repo_data) }
    end
end
