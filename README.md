# check
check is a program to help manage time and activity for git-based projects.    

# Workflow

(Optional) Step 1: Start the daemon to monitor repositories
```
$ ruby checkd.rb &
```

Step 2: Use the check tool
```
$ check -s # start a check point
...
$ check -e # end a check point and log it
```

Step 3: Work, work, work.

Step 4: Query the check points for information about past work
```
$ check --stats --all
<display stats for all repos>
$ check --logs --all 
<display logs for all repos (sorted by time)
$ check --todos 
<display TODOs for this repository>
$ check --todos
<display TODOs for all repositories>
```

# Configuration

You need to set up a shell alias to capture your git workflow. 

```
git-checkpoint() {
    check -l "$1"
    $1 
}
alias git=git-checkpoint
```

# Internals

Check is designed to work by recording "checkpoint" events and logging all
user activity in between checkpoints. These events are collected into a 
checkpoint file that is commited into the repository along with the 
repository. The development activity lives alongside the code. 

Checkpoint files are simple logs of all checkpoint and user activity.
They are structured according to the following schema.

```
Event        := CheckEvent | GitEvent
CheckEvent   := CheckCommand Time RepoState
Time         := Timestamp (ms)
RepoState    := RepoHashDigest RepoBranch
CheckCommand := Start | Stop
GitEvent     := GitCommand (more...)
GitCommand   := <log of git command>
```

