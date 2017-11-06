require 'octokit'
require 'pry'

class GithubFetcher
  ORGANISATION ||= ENV['GITHUB_ORGANISATION']
  # TODO: remove media type when review support comes out of preview
  Octokit.default_media_type = 'application/vnd.github.black-cat-preview+json'

  attr_accessor :people

  def initialize(team_members_accounts, use_labels, on_hold_labels, exclude_titles, include_repos)
    @github = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'])
    @github.user.login
    @github.auto_paginate = true
    @people = team_members_accounts
    @use_labels = use_labels
    @on_hold_labels = on_hold_labels.map(&:downcase).uniq if on_hold_labels 
    @exclude_titles = exclude_titles.map(&:downcase).uniq if exclude_titles
    @prs_on_hold = []
    @labels = {}
    @include_repos = include_repos 
  end

  def list_pull_requests
    pull_requests_from_github.each_with_object({}) do |pull_request, pull_requests|
      repo_name = pull_request.html_url.split("/")[4]
      next if hidden?(pull_request, repo_name)
      pull_requests[pull_request.title] = present_pull_request(pull_request, repo_name)
    end
  end

  private

  attr_reader :use_labels, :exclude_labels, :exclude_titles, :include_repos

  def present_pull_request(pull_request, repo_name)
    pr = {}
    pr['title'] = pull_request.title
    pr['link'] = pull_request.html_url
    pr['author'] = pull_request.user.login
    pr['repo'] = repo_name
    pr['comments_count'] = count_comments(pull_request, repo_name)
    pr['thumbs_up'] = count_thumbs_up(pull_request, repo_name)
    pr['approved'] = approved?(pull_request, repo_name)
    pr['updated'] = Date.parse(pull_request.updated_at.to_s)
    pr['labels'] = labels(pull_request, repo_name)
    pr['on_hold'] = on_hold?(pull_request, repo_name)
    pr['requested_reviewers'] = get_requested_reviewers(pull_request, repo_name)
    pr
  end

  def get_requested_reviewers pull_request, repo_name
    @github.pull_request("#{ORGANISATION}/#{repo_name}", pull_request.number).requested_reviewers
  end

  # https://developer.github.com/v3/search/#search-issues
  # returns up to 100 results per page.
  def pull_requests_from_github
    @github.search_issues("is:pr state:open user:#{ORGANISATION}").items
  end

  def person_subscribed?(pull_request)
    people.empty? || people.include?("#{pull_request.user.login}")
  end

  def count_comments(pull_request, repo)
    pr = @github.pull_request("#{ORGANISATION}/#{repo}", pull_request.number)
    (pr.review_comments + pr.comments).to_s
  end

  def count_thumbs_up(pull_request, repo)
    response = @github.issue_comments("#{ORGANISATION}/#{repo}", pull_request.number)
    comments_string = response.map {|comment| comment.body}.join
    comments_string.scan(/:\+1:/).count.to_s
  end

  def approved?(pull_request, repo)
    reviews = @github.get("repos/#{ORGANISATION}/#{repo}/pulls/#{pull_request.number}/reviews")
    reviews.any? { |review| review.state == 'APPROVED' }
  end

  def labels(pull_request, repo)
    return [] unless use_labels
    key = "#{ORGANISATION}/#{repo}/#{pull_request.number}".to_sym
    @labels[key] ||= @github.labels_for_issue("#{ORGANISATION}/#{repo}", pull_request.number)
  end

  def hidden?(pull_request, repo)
    !included_repo?(repo) ||
      excluded_title?(pull_request.title) ||
      !person_subscribed?(pull_request)
  end

  def on_hold?(pull_request, repo)
    return false unless @on_hold_labels 
    lowercase_label_names = labels(pull_request, repo).map { |l| l['name'].downcase }
    @on_hold_labels.any? { |e| lowercase_label_names.include?(e) }
  end

  def excluded_title?(title)
    exclude_titles && exclude_titles.any? { |t| title.downcase.include?(t) }
  end

  def included_repo?(repo)
    return false unless include_repos
    include_repos.include?(repo)
  end
end
