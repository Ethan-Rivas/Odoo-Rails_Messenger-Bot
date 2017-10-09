class MessengerController < Messenger::MessengerController
  def webhook
    fb_params.entries.each do |entry|
      entry.messagings.each do |messaging|
        bot_id = BotMessenger.search([['page_id','ilike',messaging.recipient_id]], 0, 2)[0]
        Messenger.config.page_access_token = BotMessenger.find(bot_id).page_token

        if messaging.callback.message?
          user = Messenger::Client.get_user_profile(messaging.sender_id) #=> hash with name, surname and profile picture
          odoo_user_id = BotMessengerContact.search([['identifier', 'ilike', messaging.sender_id]], 0, 2)

          if odoo_user_id.count >= 1
            Messenger::Client.send(
              Messenger::Request.new(
                Messenger::Elements::Text.new(text: "Your ID on the system is already registered."),
                messaging.sender_id
              )
            )
          else
            messenger_contact = BotMessengerContact.create!({"name": user["first_name"] + " " + user["last_name"], "identifier": user["id"], "bot_id": bot_id})

            Messenger::Client.send(
              Messenger::Request.new(
                Messenger::Elements::Text.new(text: "Your ID on the system has been created: #{messenger_contact.id}"),
                messaging.sender_id
              )
            )
          end

        end
      end
    end

    head :ok
  end

  def send_messages
    data = params.require(:messenger).permit(:text, :ids => [])

    data["ids"].each do | identifier |
      Messenger::Client.send(
        Messenger::Request.new(
          Messenger::Elements::Text.new(text: data["text"]), identifier
        )
      )
    end

    head :ok
  end


end
