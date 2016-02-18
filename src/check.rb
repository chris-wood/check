require 'optparse'
require 'yaml'

DEFAULT_FNAME = ".check"

class Repository
    def initialize(path)
        @path = File.absolute_path(path)
    end

    def get_branch
        branch = ""
        Dir.chdir(@path) do
            branch = `git rev-parse --abbrev-ref HEAD`
        end
        branch.strip()
    end

    def get_digest
        digest = ""
        Dir.chdir(@path) do
            digest = `git rev-parse HEAD`
        end
        digest.strip()
    end
end

def is_repository(path)
    File.exists?(File.join(path, ".git"))
end

def repository_root(path)
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

    root = path
    Dir.chdir(path) do
        root = _find_repository_root(Dir.pwd, File.absolute_path(path))
    end
    return root
end

def absolute_path(path)
    File.new(Dir.new(".").path).expand
end

class CheckpointBoundary
    def initialize(path)
        @path = path
        @dir = File.dirname(path)

        @repo = Repository.new(@dir)
    end

    def snapshot
        [@repo.get_digest, @repo.get_branch]
    end
end

class CheckpointEntry
    def initialize(path, cmd)
        @boundary = CheckpointBoundary.new(path)
        @cmd = cmd
    end

    def snapshot
        @boundary.snapshot + [@cmd]
    end
end

class Checkpointer
    def initialize(path)
        @abs_path = File.join(path, DEFAULT_FNAME)
        if !File.exists?(@abs_path) then
            File.new(@abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)

            @data = {}
            @data["logs"] = []
            File.open(@abs_path, 'w') {|f| f.write YAML::dump(@data) }
        end
    end

    def last_entry_type
        if @data["logs"].length > 0 then
            @data["logs"][-1][0]
        else
            ""
        end
    end

    def start
        load
        if last_entry_type == "START" then
            puts "You've already started a checkpoint. Time to work work work."
        else
            @data["logs"] << ["START"] + CheckpointBoundary.new(@abs_path).snapshot
            store
        end
    end

    def end
        load
        @data["logs"] << ["END"] + CheckpointBoundary.new(@abs_path).snapshot
        store
    end

    def log(cmd)
        load
        @data["logs"] << ["LOG"] + CheckpointEntry.new(@abs_path, cmd).snapshot
        store
    end

    def load
        @data = YAML::load_file(@abs_path)
    end

    def store
        File.open(@abs_path, 'w') {|f| f.write(YAML.dump(@data))}
    end
end

def usage
    puts "print something friendly"
end

if ARGV.length == 0
    usage
    exit(1)
end

flags = {"start" => false, "end" => false, "log" => false}
command = ""

ARGV.options do |opt|
    opt.banner = "Usage: check [options]"
    
    opt.on('-s', '--start', "Start a checkpoint") { |o| flags["start"] = true }
    opt.on('-e', '--end', "End a checkpoint") { |o| flags["end"] = true }
    opt.on('-l', '--log=cmd', String, "Enter a log activity") { |cmd| 
        flags["log"] = true
        command = cmd
    }
    opt.parse!
end

is_repo = is_repository(".")
abs_path = File.join(".", DEFAULT_FNAME)
if !File.exists?(abs_path) then

end

root = repository_root(".")
puts "Repository root: ", File.absolute_path(root)

checkpoint = Checkpointer.new(root)

if flags["start"]
    checkpoint.start
end
if flags["end"]
    checkpoint.end
end
if flags["log"] and command.length > 0
    checkpoint.log(command)
end

