require 'rspec/expectations'

RSpec::Matchers.define :respond_with_slack_messages do |expected|
  include SlackRubyBot::SpecHelpers

  match do |actual|
    raise ArgumentError, 'respond_with_slack_messages expects an array of ordered responses' unless expected.respond_to? :each

    client = respond_to?(:client) ? send(:client) : SlackRubyBot::Client.new

    message_command = SlackRubyBot::Hooks::Message.new
    channel, user, message, attachments = parse(actual)

    allow(Giphy).to receive(:random) if defined?(Giphy)

    allow(client).to receive(:message) do |options|
      @messages ||= []
      @messages.push options
    end

    message_command.call(client, Hashie::Mash.new(text: message, channel: channel, user: user, attachments: attachments))

    @responses = []
    expected.each do |exp|
      @responses.push(expect(client).to(have_received(:message).with(hash_including(channel: channel, text: exp)).once))
    end

    true
  end
  failure_message do |_actual|
    message = ''
    expected.each do |exp|
      message += "Expected text: #{exp}, got #{@messages[expected.index(exp)] || 'none'}\n" unless @responses[expected.index(exp)]
    end
    message
  end
end
