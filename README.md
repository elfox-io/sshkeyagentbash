# sshkeyagentbash
How I load ssh keys on my systems using the bash shell

### setup
1. Ensure openssh is installed and/or ssh-agent & ssh-add commands are available.
2. Place the code snippet in `.bashrc` into your `.bashrc` file under your home directory.
3. After logging in, run `ssh-add` to load your ssh-key into ssh-agent.

### explanation
Loading and using ssh keys can be a bit of a pain, especially if you are often in and out of systems often or use terminal multiplexer such as Screen or Tmux. There are many snippets of examples out there that "solve" this problem good enough for their users, and this is mine. I came to this after wanting to combine several different methods together as well as trial and error.

This bash code snippet does these things:
1. Runs only if this is a login shell (so no SCP/SFTP connections)
2. Creates the ssh-agent socket if it doesn't exist
3. Defines SSH_AUTH_SOCK if it isn't defined
4. Displays any loaded/active keys on login

###### code comments

```bash
if shopt -q login_shell;
```
The first line is checking for interactive login. As this little script snippet is exclusive to BASH we can use a BASH builtin to check whether or not this is a login shell or not. Without this check SCP/SFTP sessions will fail due to the unexpected commands.

```bash
  SSHAGSOCK="${HOME}/.ssh/ssh_auth_sock"
  SSHAGTMOUT=28800 # ssh-agent timeout (14400 = 4 hours)
```
Setting variables of where our SSH Socket will be located as well as a timeout value for storing keys inside the agent socket. The reasons for doing this are:
- Setting a socket path ensures everything we want to know about the ssh-agent socket CAN know exactly where it is, as we have defined it.
- Setting a timeout value gives _some_ amount of private key security on shared systems. As anyone can `ps -ef|grep ssh-agent` and then anyone with privledges to access that process can use YOUR private key. We can't get around the process being visible, but we mitigate the chances of someone else using our identity by giving the loaded key a timeout value. I eventually fell on 8 hours for obvious work reasons. Note that this times out loaded keys and not the ssh-agent itself.

```bash
  if [ ! -S "${SSHAGSOCK}" ] ; then
    eval "$(ssh-agent -t ${SSHAGTMOUT} -a ${SSHAGSOCK} > /dev/null)"
    echo "--- ssh-agent socket created ---"
  fi
```
If a socket does not exist in the location we specified, then create it with the values we specify and let us know it was created.

```bash
  if [ -z "${SSH_AUTH_SOCK}" ] ; then
    export SSH_AUTH_SOCK="${SSHAGSOCK}"
    KEYOUT=$(ssh-add -l)
    echo "--- ${KEYOUT} ---"
  fi
```
If the variable `SSH_AUTH_SOCK` is not defined then define it so the `ssh-add` command knows where to look for loaded ssh-keys. Then, show us any loaded keys.

And... that's about it. Simple but useful.

#### Minutia

##### Screen
Screen may or may not work right off the bat. If you are running a newer version of BASH or Screen, it will likely "just work", but if it doesn't you can set this option inside of your `$HOME/.screenrc"
```bash
# Custom 'screen' configuration file

# Don't display the copyright page
startup_message off

# Use the created socket for ssh-agent
setenv SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock
setenv TMOUT 43200
```
I placed an entire `.screenrc` file above, but all that you'd need is the `setenv SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock` line.

##### TMUX
- [ ] to-do: put in the actual tmux config file location and config line (though this should be easy to find if you need it)

##### WSL
When trying this setup within a CentOS WSL I came across an issue where sometimes the socket existed but the ssh-agent was not. When this happens this simple setup fails because you can no longer use the existing socket. The easy solution was to check for this condition and remove it.
```bash
SSHAGSTAT=$(ps -u ${USER}|grep ssh-agent|grep -v grep >/dev/null;echo $?)

# If the socket exists but ssh-agent isn't running, remove the socket as we won't be able to use it
if [ -S "${SSHAGSOCK}" -a "${SSHAGSTAT}" == "1" ] ; then
  rm "${SSHAGSOCK}"
fi
```
The snippet above goes under the other two variable definitions and before creating a socket if it doesn't exist.
