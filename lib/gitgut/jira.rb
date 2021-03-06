require 'httparty'

module Gitgut
  # Namespace around Atlassian/JIRA objects
  module Jira
    # A JIRA ticket
    class Ticket
      attr_reader :key, :assignee, :status

      def initialize(payload)
        @key = payload['key']
        # TODO: use Mash?
        if payload['fields']['assignee']
          @assignee = payload['fields']['assignee']['name']
          @assignee_display_name = payload['fields']['assignee']['displayName']
        end

        if payload['fields']['status']
          @status = payload['fields']['status']['name']
        end
      end

      def assigned_to_me?
        assignee == Settings.jira.username
      end

      def assignee_initials
        return '' unless assignee
        words = @assignee_display_name.split(/ +/)
        "#{words.first} #{words.last[0]}."
      end

      def ready_for_release?
        status == 'Ready for Release'
      end

      def in_review?
        status == 'In Review'
      end

      def done?
        ready_for_release? || released? || closed?
      end

      def closed?
        status == 'Closed'
      end

      def released?
        status == 'Released'
      end

      def color
        return :light_blue if assigned_to_me?
        case status
        when 'In Functional Review', 'In Review'
          :white
        when 'In Development', 'Open'
          :light_blue
        when 'Ready for Release', 'Released'
          :green
        when 'Closed'
          :light_black
        else
          :white
        end
      end
    end

    def self.request(query)
      response = Request.new(query).perform!
      JSON.parse(response.body)
    end

    # Wrapper around a JQL query for JIR
    class Request
      DEFAULT_OPTIONS = {
        headers: { 'Content-Type' => 'application/json' }
      }.freeze

      JQL_PARAM_NAME = 'jql'.freeze

      def initialize(query)
        @query = query
      end

      # TODO: Maybe use a flag like performed? and store the response in an
      # attr_reader
      def perform!
        options = DEFAULT_OPTIONS.merge(
          basic_auth: auth_options
        )
        HTTParty.get(url, options)
      end

      def url
        url = URI.parse(Settings.jira.endpoint)
        url.query = "#{JQL_PARAM_NAME}=#{URI.escape(@query)}"
        url
      end

      def auth_options
        {
          username: Settings.jira.username,
          password: Settings.jira.password
        }
      end
    end
  end
end
