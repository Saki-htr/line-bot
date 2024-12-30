class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'] == "今日はきますか?"
            client.reply_message(event['replyToken'], attendance_confirm_buttons)
          end
        end
      when Line::Bot::Event::Postback
        handle_postback(event)
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
    end
  end

  def attendance_confirm_buttons
    {
      type: 'template',
      altText: '出欠確認',
      template: {
        type: 'confirm',
        text: '今日はきますか?',
        actions: [
          {
            type: 'postback',
            label: 'はい',
            data: 'attendance=yes'
          },
          {
            type: 'postback',
            label: 'いいえ',
            data: 'attendance=no'
          }
        ]
      }
    }
  end

  def handle_postback(event)
    data = URI.decode_www_form(event['postback']['data']).to_h
    response_message = case data['attendance']
                      when 'yes'
                        'ご参加ありがとうございます！'
                      when 'no'
                        '承知いたしました。また次回お待ちしています。'
                      end
    
    client.reply_message(event['replyToken'], {
      type: 'text',
      text: response_message
    })
  end
end
