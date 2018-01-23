class MergeMessageBuilder

  attr_accessor :pull_requests, :report, :mood, :poster_mood, :image_attachment

  def initialize(pull_requests, mode=nil)
    @pull_requests = pull_requests.map{ |_title, pull_request| pull_request } 
    @unmerged_pull_requests = @pull_requests.select { |pull_request| is_unmerged?(pull_request) } 
    @poster_mood = "merge"
    @image_attachment = get_random_merge_image

    org_config
  end

  def org_config
    @org_config ||= YAML.load_file(configuration_filename) if File.exist?(configuration_filename)
  end

  def configuration_filename
    @configuration_filename ||= "./config/#{ENV['GITHUB_ORGANISATION']}.yml"
  end

  def build
    @message = ""

    add_unmerged_requests

    return @message
  end

  def add_unmerged_requests
    if @unmerged_pull_requests.empty?
      @message += "\n\n No Outstanding PRs to Merge."
    else
      @message += "\n\n *These approved PRs need to be merged.*\n\n"
      @unmerged_pull_requests.each_with_index do |pr, index|
        @message += ">#{index+1}) <#{pr["link"]}|#{pr["title"]}>.\n"
      end
    end
  end

  # Any PR that is approved but not merged
  def is_unmerged?(pull_request)
    pull_request['approved']
  end

  def get_random_merge_image
    if @unmerged_pull_requests.any?
      org_config["gifs"].sample
    end
  end

end
