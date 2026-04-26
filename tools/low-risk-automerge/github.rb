#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "common"

module LowRiskAutomerge
  Decision = Struct.new(:pr_number, :merged, :reason, keyword_init: true) do
    def merged?
      merged
    end
  end

  class GitHubClient
    API_VERSION = "2022-11-28"

    def initialize(repo:, token:, api_url: ENV.fetch("GITHUB_API_URL", "https://api.github.com"))
      @repo = repo
      @token = token
      @api_url = api_url
    end

    def get_json(path)
      JSON.parse(curl(path))
    end

    def post_json(path, payload)
      curl(path, method: "POST", body: JSON.generate(payload))
    end

    def put_json(path, payload)
      curl(path, method: "PUT", body: JSON.generate(payload))
    end

    private

    attr_reader :api_url, :repo, :token

    def curl(path, method: nil, body: nil)
      command = [
        "curl", "-fsSL",
        "-H", "Accept: application/vnd.github+json",
        "-H", "Authorization: Bearer #{token}",
        "-H", "X-GitHub-Api-Version: #{API_VERSION}",
        "-H", "Content-Type: application/json"
      ]
      command.concat(["-X", method]) if method
      command.concat(["-d", body]) if body
      command << "#{api_url}/repos/#{repo}#{path}"
      stdout, stderr, status = Open3.capture3(*command)
      raise HttpError, stderr.strip unless status.success?

      stdout
    end
  end

  class GitHubRunner
    OWN_CHECK_NAME = "Low-Risk Automerge"

    def initialize(client:, repo:, bot_author: ENV.fetch("LOW_RISK_AUTOMERGE_BOT_AUTHOR", "github-actions[bot]"), event_path: ENV["LOW_RISK_AUTOMERGE_EVENT_PATH"], stdout: $stdout)
      @client = client
      @repo = repo
      @bot_author = bot_author
      @event_path = event_path
      @stdout = stdout
    end

    def run
      candidate_prs.each { |pr| stdout.puts(evaluate_pr(pr).reason) }
    end

    def evaluate_pr(pr)
      number = pr.fetch("number")
      head_sha = pr.fetch("head").fetch("sha")

      return blocked(pr, "Not merging PR ##{number}: fork pull requests are not eligible") if fork_pr?(pr)

      metadata = latest_trusted_metadata(number)
      return blocked(pr, "Not merging PR ##{number}: no trusted Codex review metadata") unless metadata
      return blocked(pr, "Not merging PR ##{number}: stale review metadata") unless metadata.reviewed_head == head_sha
      return blocked(pr, "Not merging PR ##{number}: review is not low-risk") unless metadata.risk == "low" && metadata.merge_ok
      return blocked(pr, "Not merging PR ##{number}: check runs are not all successful") unless check_runs_success?(head_sha)
      return blocked(pr, "Not merging PR ##{number}: combined status is not successful") unless combined_status_success?(head_sha)

      client.put_json("/pulls/#{number}/merge", { "sha" => head_sha, "merge_method" => "rebase" })
      Decision.new(pr_number: number, merged: true, reason: "Merged PR ##{number}")
    rescue HttpError => e
      blocked(pr, "Not merging PR ##{number}: merge failed: #{e.message}")
    end

    private

    attr_reader :bot_author, :client, :event_path, :repo, :stdout

    def candidate_prs
      payload = event_payload
      return [] if payload.key?("issue") && !payload.dig("issue", "pull_request")

      pr_number = payload.dig("inputs", "pr_number") || payload.dig("issue", "number") || payload.dig("pull_request", "number")
      return [client.get_json("/pulls/#{Integer(pr_number)}")] if pr_number.to_s.match?(/\A\d+\z/) && pr_event?(payload)

      client.get_json("/pulls?state=open")
    end

    def pr_event?(payload)
      payload.key?("pull_request") || payload.dig("issue", "pull_request") || payload.dig("inputs", "pr_number")
    end

    def event_payload
      return {} unless event_path && File.file?(event_path)

      JSON.parse(File.read(event_path))
    rescue JSON::ParserError
      {}
    end

    def fork_pr?(pr)
      pr.dig("head", "repo", "full_name") != pr.dig("base", "repo", "full_name")
    end

    def latest_trusted_metadata(number)
      trusted_comments = client.get_json("/issues/#{number}/comments").select do |comment|
        comment.dig("user", "login") == bot_author
      end
      latest = trusted_comments.max_by { |comment| Time.parse(comment.fetch("created_at", "1970-01-01T00:00:00Z")) }
      return nil unless latest

      MetadataParser.parse(latest["body"])
    end

    def check_runs_success?(head_sha)
      runs = client.get_json("/commits/#{head_sha}/check-runs").fetch("check_runs")
      runs.all? do |run|
        next true if run["name"] == OWN_CHECK_NAME && run["status"] == "in_progress"

        run["status"] == "completed" && run["conclusion"] == "success"
      end
    end

    def combined_status_success?(head_sha)
      client.get_json("/commits/#{head_sha}/status").fetch("state") == "success"
    end

    def blocked(pr, reason)
      number = pr.fetch("number")
      return Decision.new(pr_number: number, merged: false, reason: reason) if refusal_comment_exists?(number, reason)

      client.post_json("/issues/#{number}/comments", { "body" => reason })
      Decision.new(pr_number: number, merged: false, reason: reason)
    end

    def refusal_comment_exists?(number, reason)
      client.get_json("/issues/#{number}/comments").any? do |comment|
        comment.dig("user", "login") == bot_author && comment["body"].to_s.include?(reason)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  repo = ENV.fetch("LOW_RISK_AUTOMERGE_REPO", ENV["GITHUB_REPOSITORY"])
  token = ENV.fetch("GITHUB_TOKEN")
  client = LowRiskAutomerge::GitHubClient.new(repo: repo, token: token)
  LowRiskAutomerge::GitHubRunner.new(client: client, repo: repo).run
end
