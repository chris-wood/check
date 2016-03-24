require 'optparse'
require 'yaml'
require 'date'

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

class TaskManager
    def initialize(root, directory, task_name)
        @path = root
        @check_path = File.join(root, directory)
        @abs_path = File.join(@check_path, task_name)

        if !File.exists?(@abs_path) then
            File.new(@abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
            File.open(@abs_path, 'w') {|f| f.write "" }
        end
    end

    def execute_list
        puts `TODO_DIR=#{@check_path} todo.sh list`
    end

    def execute_add(cmd)
        puts `TODO_DIR=#{@check_path} todo.sh add #{cmd}`
    end

    def execute_do(cmd)
        puts `TODO_DIR=#{@check_path} todo.sh do #{cmd}`
    end
end

class Checkpointer
    def initialize(root, directory, checkpoint_name)
        @path = root
        @abs_path = File.join(root, directory)
        @current_file = File.join(@abs_path, checkpoint_name)
        create_dir_if_missing
    end

    def create_dir_if_missing
        if !Dir.exists?(@abs_path) then
            Dir.chdir(@path) do
                Dir.mkdir(DEFAULT_FNAME)
            end
        end
    end

    def is_active
        File.exists?(@current_file)
    end

    def next_checkpoint
        today = Date.today.strftime("%Y%m%d").to_s
        maxnum = 0
        Dir.chdir(@abs_path) do
            Dir['*'].each do |f|
                if f.to_s.include? today then
                    parts = f.split("-")
                    num = parts[-1].to_i
                    if num > maxnum then
                        maxnum = num
                    end
                end
            end
        end
        maxnum = maxnum + 1

        return "check-" + today.to_s + "-" + maxnum.to_s
    end

    def start
        if is_active
            puts "You've already started a checkpoint."
        else
            create_checkpoint(next_checkpoint)
            load
            @data << ["START"] + CheckpointBoundary.new(@abs_path).snapshot
            store
        end
    end

    def end
        if not is_active
            puts "You are not in an active checkpoint."
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
        @data = YAML::load_file(full_path)
    end

    def store
        full_path = current_file_name
        File.open(full_path, 'w') {|f| f.write(YAML.dump(@data))}
    end
end
