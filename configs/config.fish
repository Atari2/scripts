if status is-interactive
    # Commands to run in interactive sessions can go here
    set cmd (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    eval $cmd
    oh-my-posh init fish --config /home/alessiorosiello/.config/atomic.omp.json | source
    nvm use 20 --silent
end
