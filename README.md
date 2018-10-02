### Usage

1. Clone this repository onto your local machine
2. Check the appropriate config settings in `config/deploy` or add a new one
3. `bundle exec cap [target] deploy` and specify the branch from the Github repo defined as the `repo_url` in the `config/deploy` file

### Adding a new deployment target (new server)

1. Add a `config/deploy/hostname` file and set it up accordingly
2. Update the URL of your private repository that houses your server configuration files. This will typically require you to add the server's SSH key to the private repo's list of authorized deployment keys.

#### Troubleshooting

1. Make sure the server's ssh key has been added to the configuration repo
2. Make sure the correct user and path are specified in the `config/deploy` file 
