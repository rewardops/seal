# Seal

## Basics 

This is a Slack bot that publishes a team's pull requests to their Slack Channel, once provided the organisation name and the team members' github names. 

![image](https://github.com/binaryberry/seal/blob/master/images/readme/informative.png)
![image](https://github.com/binaryberry/seal/blob/master/images/readme/angry.png)

## Setup 

### Config files

#### Secrets

Copy the `.env.sample` to `.env` file and add in the correct values. 

- To get a new `GITHUB_TOKEN`, head to: https://github.com/settings/tokens
- To get a new `SLACK_WEBHOOK`, head to: https://slack.com/services/new/incoming-webhook

#### Teams

Team setup can be found in `config/rewardops.yml`. Linking slack users to their github usernames is found under `slack_users`.

### Bash scripts

In your forked repo, include your team names in the appropriate bash script. Ex. `bin/morning_seal.sh`.

### Slack configuration

You should also set up the following custom emojis in Slack:
- :informative_seal:
- :angrier_seal:
- :seal_of_approval:
- :happyseal:
- :halloween_informative_seal:
- :halloween_angrier_seal:
- :halloween_seal_of_approval:
- :festive_season_informative_seal:
- :festive_season_angrier_seal:
- :festive_season_seal_of_approval:
- :manatea:
- :change:

You can use the images in images/emojis that have the corresponding names.

## Usage 

`./bin/seal.rb team_name` 

## Testing

Just run `rspec` in the command line

## License

See the [LICENSE](LICENSE) file for license rights and limitations (MIT).
