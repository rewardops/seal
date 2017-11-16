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
      %w(
        https://media.giphy.com/media/cFkiFMDg3iFoI/giphy.gif
        https://media.giphy.com/media/xTiTnqEbrWfX7xA9TW/giphy.gif
        https://media.giphy.com/media/Mz6BMFMgkLDpe/giphy.gif
        https://media.giphy.com/media/K6PzlAKOm221G/giphy.gif
        https://media.giphy.com/media/v9w2V9UUQqyDm/giphy.gif
        https://media.giphy.com/media/D0WOL0ogZIoG4/giphy.gif
        https://media.giphy.com/media/mW0zaDZZ9aYzS/giphy.gif
        https://media.giphy.com/media/ZH5UpiZJiRRgQ/giphy.gif
        https://media.giphy.com/media/1Ri3cZmDNFVtK/giphy.gif
        https://media.giphy.com/media/10sfl8BfZocbFC/giphy.gif
        https://media.tenor.com/images/d3972747d472654b151a8744671d7709/tenor.gif
        https://media.giphy.com/media/7EMcwG3wN6kta/giphy.gif
      ).sample
    end
  end

end
