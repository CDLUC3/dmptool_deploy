### Usage

1. Clone this repository onto your local machine
2. Check the appropriate config settings in `config/deploy` or add a new one
3. `bundle exec cap [config/deploy/file] deploy` and specify the branch from the Github repo defined as the `repo_url` in the `config/deploy` file

#### Troubleshooting

1. Make sure the server's ssh key has been added to the configuration repo
2. Make sure the correct user and path are specified in the `config/deploy` file 

