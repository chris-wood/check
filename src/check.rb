require 'optparse'
require 'yaml'
require 'date'

DEFAULT_FNAME = ".check"
DEFAULT_CHECKPOINT_FNAME = "current_check"

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
        @path = path
        @abs_path = File.join(path, DEFAULT_FNAME)
        @current_file = File.join(@abs_path, DEFAULT_CHECKPOINT_FNAME) 
        create_dir_if_missing
    end

    def create_dir_if_missing
        if !Dir.exists?(@abs_path) then
            Dir.chdir(@path) do
                puts Dir.pwd
                Dir.mkdir(DEFAULT_FNAME)
            end
        end
    end

    def is_active
        File.exists?(File.join(@abs_path, DEFAULT_CHECKPOINT_FNAME))
    end

    def next_checkpoint
        today = Date.today.strftime("%Y%m%d").to_s
        maxnum = 0
        Dir.chdir(@abs_path) do 
            puts "in #{Dir.pwd} looking for check-#{today}"
            Dir['*'].each do |f|
                if f.to_s.include? today then
                    parts = f.split("-")
                    num = parts[-1].to_i
                    if num > maxnum then
                        maxnum = num
                    end
                end
                puts "checked #{f} and maxnum is #{maxnum.to_s}"
            end
        end
        maxnum = maxnum + 1

        return "check-" + today.to_s + "-" + maxnum.to_s
    end

    def start
        if is_active
            puts "You've already started a checkpoint. Time to work work work."
        else
            create_checkpoint(next_checkpoint)
            load
            @data << ["START"] + CheckpointBoundary.new(@abs_path).snapshot
            store
        end
    end

    def end
        if not is_active
            puts "You are not in a checkpoint."
        else
            load
            @data << ["END"] + CheckpointBoundary.new(@abs_path).snapshot
            store

            File.delete(@current_file)
        end
    end

    # TODO: move these creation/writing init functions to a separate method
    def create_checkpoint(filename)
        full_path = File.join(@abs_path, filename)
        File.new(full_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
        @data = []
        File.open(full_path, 'w') {|f| f.write YAML::dump(@data) }

        # TODO: we should be storing relative paths, not absolute paths
        File.new(@current_file, File::CREAT|File::TRUNC|File::RDWR, 0644)
        File.open(@current_file, 'w') {|f| f.write(full_path) }
    end

    def log(cmd)
        load
        @data << ["LOG"] + CheckpointEntry.new(@abs_path, cmd).snapshot
        store
    end

    def current_file_name
        current = File.open(@current_file, "r")
        full_path = current.read.to_s
        return full_path
    end

    def load
        full_path = current_file_name
        puts "Loading #{full_path} to append"
        @data = YAML::load_file(full_path)
    end

    def store
        full_path = current_file_name
        File.open(full_path, 'w') {|f| f.write(YAML.dump(@data))}
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
todo = ""
todo_id = ""

ARGV.options do |opt|
    opt.banner = "Usage: check [options]"
    
    opt.on('-s', '--start', "Start a checkpoint") { |o| flags["start"] = true }
    opt.on('-e', '--end', "End a checkpoint") { |o| flags["end"] = true }
    opt.on('-t', '--todo=task', String, "Add a TODO item") { |task| 
        flags["todo"] = true 
        todo = task
    }
    opt.on('-l', '--list', String, "List the existing TODOs") { |o| 
        flags["list"] = true
    }
    opt.on('-f', '--finish=id', String, "Finish the specified TODO") { |id| 
        flags["finish"] = true
        todo_id = id
    }
    opt.on('-l', '--log=cmd', String, "Enter a log activity") { |cmd| 
        flags["log"] = true
        command = cmd
    }
    opt.parse!
end

is_repo = is_repository(".")
abs_path = File.join(".", DEFAULT_FNAME)
if !File.exists?(abs_path) then
    # TODO: create it
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

