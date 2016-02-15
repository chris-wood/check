require 'optparse'
require 'yaml'

DEFAULT_FNAME = ".check"

class Repositry
    def iniitalize(path)
        @path = File.absolute_path(path)
    end

    def get_branch
        branch = ""
        Dir.chdir(@path) do
            branch = `git rev-parse --abbrev-ref HEAD`
        end
        return branch
    end

    def get_digest
        digest = ""
        Dir.chdir(@path) do
            digest = `git rev-parse HEAD`
        end
        return digest
    end
end

def is_repository(path)
    File.exists?(File.join(path, ".git"))
end

def _find_repository_root(path, prev)
    Dir.chdir(path) do
        cwd = Dir.pwd
        out = `git status 2>&1`
        if out.include?("fatal: ")
            return prev
        else
            return _find_repository_root(File.expand_path("..", Dir.pwd), cwd)
        end
    end
end

def repository_root(path)
    root = path
    Dir.chdir(path) do
        root = _find_repository_root(Dir.pwd, File.absolute_path(path))
    end
    return root
end

def absolute_path(path)
    File.new(Dir.new(".").path).expand
end

class Checkpoint
    def initialize(path)
        @abs_path = File.join(path, DEFAULT_FNAME)
        if !File.exists?(@abs_path) then
            File.new(@abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)

            @data = {}
            @data["logs"] = []
            File.open(@abs_path, 'w') {|f| f.write YAML::dump(@data) }
        end
    end

    def start()
        load()
        puts "start!"
        @data["logs"] << "START at TIME X"
        store()
    end

    def end()
        load()
        puts "end!"
        @data["logs"] << "END at TIME X"
        store()
    end

    def load()
        @data = YAML::load_file(@abs_path)
    end

    def store()
        puts "store!"
        File.open(@abs_path, 'w+') {|f| f.write(YAML.dump(@data))}
    end
end

flags = {"start" => false, "end" => false}

OptionParser.new do |opt|
    opt.banner = "Usage: check [options]"
    opt.on('-s', '--start') { |o| flags["start"] = true }
    opt.on('-e', '--end') { |o| flags["end"] = true }
end.parse!

if ARGV.length == 0
    puts opt.banner
    exit(1)
end

is_repo = is_repository(".")
abs_path = File.join(".", DEFAULT_FNAME)
if !File.exists?(abs_path) then

end

root = repository_root(".")
puts "Repository root: ", File.absolute_path(root)

checkpoint = Checkpoint.new(root)

if flags["start"]
    checkpoint.start()
end
if flags["end"]
    checkpoint.end()
end
