class MessageBuilder

  attr_accessor :pull_requests, :report, :mood, :poster_mood

  def initialize(pull_requests, mode=nil)
    @pull_requests = pull_requests.map{ |_title, pull_request| pull_request }
                                  .select{ |pull_request| !is_approved?(pull_request) }

    @old_pull_requests = @pull_requests.select { |pull_request| is_old?(pull_request) }
    @stale_holds = @pull_requests.select { |pull_request| stale_hold?(pull_request) }
    @recent_pull_requests = @pull_requests.select { |pull_request| is_recent?(pull_request) } 

    # Defaults
    @poster_mood = "approval"
    @message = ""

    org_config
  end

  def org_config
    @org_config ||= YAML.load_file(configuration_filename) if File.exist?(configuration_filename)
  end

  def configuration_filename
    @configuration_filename ||= "./config/#{ENV['GITHUB_ORGANISATION']}.yml"
  end

  def build
    add_message_header

    add_old_pull_requests
    add_stale_holds
    add_recent_pull_requests

    add_message_footer

    return @message
  end

  def add_message_header
    if @pull_requests.empty?
      @message += "*Aloha team! It's a beautiful day! :happyseal: :happyseal: :happyseal:*\n\n*No pull requests to review today! :rainbow: :sunny: :metal: :tada:*"
    else 
      @message += header_and_mood_for_existing_prs
    end
  end

  def add_message_footer
    ["Remember each time you forget to review your pull requests, a baby seal dies.",
    "Merry Reviewing!"]
  end

  def header_and_mood_for_existing_prs 
    if !@old_pull_requests.empty? 
      @poster_mood = "angry"
      "*AAAAAAARGH! #{pluralize('this', @old_pull_requests.length)} #{pluralize('pull request has', @old_pull_requests.length)} not been updated in over 2 days.*\n\n\n"
    elsif !@stale_holds.empty?
      @poster_mood = "upset"
      "*These PRs are staler than that box of triscuits from when you were going through that healthy eating phase.*\n\n\n"
    else
      @poster_mood = "informative"
      "*Hello team!* \n\n *Here are the pull requests that need to be reviewed today:*\n\n\n"
    end
  end

  def add_old_pull_requests
    @old_pull_requests.each_with_index do |pull_request, index|
      @message += present(pull_request, index)
    end
  end

  def add_recent_pull_requests
    if !@recent_pull_requests.empty? && @poster_mood != "informative"
      @message += "\n\n*There are also these pull requests that need to be reviewed today:*\n\n"
    end

    @recent_pull_requests.each_with_index do |pull_request, index|
      @message += present(pull_request, index)
    end
  end

  def add_stale_holds
    if !@stale_holds.empty? && @poster_mood != "upset"
      @message += "\n\n*There are also these pull requests that have been on hold for quite some time:*\n\n"
    end

    @stale_holds.each_with_index do |pull_request, index|
      @message += present(pull_request, index)
    end
  end

  def on_hold?(pull_request)
    return pull_request['on_hold']   
  end

  def stale_hold?(pull_request)
    if on_hold?(pull_request)   
      return rotten?(pull_request)
    end
    return false
  end

  def is_old?(pull_request)
    if !on_hold?(pull_request)   
      return rotten?(pull_request)
    end
    return false
  end

  def is_recent?(pull_request)
    !on_hold?(pull_request) && !is_old?(pull_request)
  end

  # Any PR that is approved but not merged
  def is_approved?(pull_request)
    pull_request['approved']
  end

  def rotten?(pull_request)
    today = Date.today
    actual_age = (today - pull_request['updated']).to_i
    if today.monday?
      weekdays_age = actual_age - 2 # If Monday is a holiday, nothing will even be posted to slack. See SlackPoster
    elsif today.tuesday?
      weekdays_age = actual_age - (1 + holidays_count(today))
    else
      weekdays_age = actual_age - (holidays_count(today))
    end
    weekdays_age > 2
  end

  private

  def holidays_count today
    end_date = today
    start_date = today - (today.wday - 1)
    Holidays.between(start_date, end_date, :observed, :ca_on).count
  end

  def pluralize(key, count)
    plural_array_index = (count.to_i == 1 ? 0 : 1)

    values_to_pluralize = {
      "this" => ["this", "these"],
      "pull request has" => ["pull request has", "pull request have"],
      "comment" => ["comment", "comments"]
    }

    values_to_pluralize[key][plural_array_index]
  end

  # TODO: This is uber ugly, perhaps we could add some kind of templating engine
  
  def present(pull_request, index)
    index += 1
    pr = pull_request
    thumbs_up = ''
    thumbs_up = " | #{pr["thumbs_up"].to_i} :+1:" if pr["thumbs_up"].to_i > 0
    if pr["on_hold"]
      on_hold = " :no_entry: "
      changes_requested = ""
    else
      on_hold = ""
      changes_requested = pr["requested_reviewers"].empty? ? " :change: " : " :mag: " 
    end
    <<-EOF.gsub(/^\s+/, '')
    >#{index}\) _#{pr["repo"]}_ | #{changes_requested}#{on_hold}#{format_author(pr)}
    >#{labels(pr)} <#{pr["link"]}|#{pr["title"]}>
    EOF
  end

  def format_author pull_request 
    if pull_request["requested_reviewers"].empty?
      author = format_github_handle(pull_request["author"])
      return "Requiring changes from #{author}"
    else
      usernames = []
      pull_request["requested_reviewers"].each do |reviewer|
        usernames << format_github_handle(reviewer[:login])
      end
      return "Requiring reviews from #{usernames.join(', ')}" 
    end
  end

  def format_github_handle github_handle
    if @org_config["slack_users"] && @org_config["slack_users"][github_handle]
      return "@#{@org_config['slack_users'][github_handle]}"
    end
    return github_handle
  end

  def age_in_days(pull_request)
    (Date.today - pull_request['updated']).to_i
  end

  def days_plural(days)
    if days == 0
      'today'
    elsif days == 1
      "yesterday"
    elsif days < 0
      "recently"
    else
      "#{days} days ago"
    end
  end

  def labels(pull_request)
    pull_request['labels'].map{ |label| "[#{label['name']}]" }.join(' ')
  end
end
