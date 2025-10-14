module SlackServices
  class StackTrace < Notifier
    def initialize title:, stack_trace:
      @title = title
      @stack_trace = stack_trace
    end

    def env
      ENV['SLACK_WEBHOOKS']
    end

    def payload
      {
        text: @title,
        attachments: [
          { text: @stack_trace },
        ]
      }
    end

    def payload_adds
      {
        username: 'STACK_TRACE',
        channel: webhook('stack-trace-channel'),
      }
    end
  end
end
