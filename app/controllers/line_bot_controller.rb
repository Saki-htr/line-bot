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
      when Line::Bot::Event::Postback
        handle_postback(event)
      end
    end

    head :ok
  end

  def send_attendance_check
    # memo: 友達全員のユーザーIDを取得できるのは認証済アカウントまたはプレミアムアカウントのみなので、個別に指定する
    # 参考: https://developers.line.biz/ja/docs/messaging-api/getting-user-ids/#get-all-friends-user-ids
    user_id = ENV["SAKI_LINE_USER_ID"]

    client.push_message(
      user_id,
      attendance_confirm_buttons
    )

    head :ok
  rescue Line::Bot::API::Error => e
    Rails.logger.error "LINE API Error: #{e.message}"
    head :internal_server_error
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
    user_id = event['source']['userId']

    response_message = case data['attendance']
                      when 'yes'
                        '分かりました。お待ちしています〜。'
                      when 'no'
                        '分かりました。無理しないでくださいね〜'
                      end

    client.reply_message(event['replyToken'], {
      type: 'text',
      text: response_message
    })
  end
end
