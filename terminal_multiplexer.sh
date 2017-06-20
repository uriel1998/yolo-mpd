#!/bin/bash

# Solutions from
# http://superuser.com/questions/363614/leave-xterm-open-after-task-is-complete
# http://unix.stackexchange.com/questions/3197/how-to-identify-which-xterm-a-shell-or-process-is-running-in


snark=$(echo $WINDOWID)
wmctrl -i -r "$snark" -T "Our Tmux" 

session="MPD"

# set up tmux
tmux start-server

# create a new tmux session, starting vim from a saved session in the new window
tmux new-session -d -s $session 

# Select pane 1, set dir to api, run vim
tmux selectp -t 1 
tmux send-keys "ncmpcpp" C-m

# Split pane 1 horizontal by 65%, start redis-server
tmux splitw -v -p 40
tmux send-keys "cava" C-m 

# Select pane 2 
tmux selectp -t 2
# Split pane 2 vertically by 25%
tmux splitw -h -p 25

# select pane 3, set to api root
tmux selectp -t 3
tmux send-keys "./terminal_covers.sh" C-m 

# Select pane 1
tmux selectp -t 1


# Finished setup, attach to the tmux session!
tmux attach-session -t $session
